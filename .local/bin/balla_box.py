import gi
import signal
import sys
import os
import subprocess
from datetime import datetime

gi.require_version("Gst", "1.0")
from gi.repository import Gst, GLib

Gst.init(None)

class BallaBox:
    def __init__(self):
        self.loop = GLib.MainLoop()
        self.pipeline = None
        
        # --- KONFIGURACE ---
        self.width, self.height = 1280, 720
        self.fps = "30/1"
        self.rtmp_url = "rtmp://192.168.76.12:9000/live/rtmp"
        
        # Audio zařízení (Rode NT-USB a Monitor plochy)
        self.mic_src = "alsa_input.usb-RODE_Microphones_RODE_NT-USB-00.analog-stereo"
        self.desktop_src = "alsa_output.usb-RODE_Microphones_RODE_NT-USB-00.analog-stereo.monitor"
        
        self.timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
	# Dynamické zjištění domovské složky
        home_dir = os.path.expanduser("~")
        self.file_path = f"{home_dir}/Videa/zaznam_{self.timestamp}.mkv"
        
        # Vytvoření složky, pokud neexistuje
        os.makedirs(os.path.dirname(self.file_path), exist_ok=True)
        self.build_pipeline()

    def build_pipeline(self):
        # Rozměry pro kameru v rohu (Picture-in-Picture)
        cam_w, cam_h = 320, 240
        
        # Caps pro Rockchip HW enkodér (NV12 je nutnost)
        target_caps = f"video/x-raw,format=NV12,width={self.width},height={self.height},framerate={self.fps}"
        pip_caps = f"video/x-raw,format=NV12,width={cam_w},height={cam_h},framerate={self.fps}"

        parts = [
            # --- VIDEO CORE ---
            f"compositor name=comp latency=300000000 "
            f"sink_0::zorder=0 "
            f"sink_1::zorder=1 sink_1::xpos={self.width - cam_w} sink_1::ypos={self.height - cam_h} ! "
            f"videorate ! {target_caps} ! "
            f"mpph264enc bps=2800000 rc-mode=cbr gop=60 header-mode=1 ! h264parse ! tee name=vtee",

            # --- PLOCHA (Vstup 0) ---
            f"ximagesrc use-damage=false remote=true do-timestamp=true ! video/x-raw,framerate={self.fps} ! "
            f"videoconvert ! videoscale ! {target_caps} ! "
            f"queue max-size-buffers=30 max-size-time=1000000000 ! comp.sink_0",

            # --- KAMERA (Vstup 1) ---
            f"v4l2src device=/dev/video1 do-timestamp=true ! video/x-raw,width=640,height=480,framerate={self.fps} ! "
            f"videoconvert ! videoscale ! {pip_caps} ! "
            f"queue max-size-buffers=30 max-size-time=1000000000 ! comp.sink_1",

            # --- AUDIO CORE ---
            f"audiomixer name=amix latency=200000000 alignment-threshold=40000000 ! "
            f"audio/x-raw,rate=48000,channels=2 ! audioconvert ! voaacenc bitrate=128000 ! tee name=atee",

            # Mikrofon (oprava synchronizace a resample)
            f"pulsesrc device={self.mic_src} do-timestamp=true provide-clock=true slave-method=resample ! "
            f"queue max-size-buffers=100 max-size-time=2000000000 ! "
            f"audioconvert ! audioresample ! "
            f"volume volume=1.5 ! audio/x-raw,rate=48000 ! amix.",

            # Zvuk plochy
            f"pulsesrc device={self.desktop_src} do-timestamp=true provide-clock=false slave-method=resample ! "
            f"queue max-size-buffers=100 max-size-time=2000000000 ! "
            f"audioconvert ! audioresample ! "
            f"volume volume=0.4 ! audio/x-raw,rate=48000 ! amix.",

            # --- VÝSTUPY ---
            # Lokální záznam
            f"vtee. ! queue leaky=downstream max-size-time=2000000000 max-size-buffers=0 max-size-bytes=0 ! matroskamux name=mux ! filesink location={self.file_path} async=false",
            f"atee. ! queue leaky=downstream max-size-time=2000000000 max-size-buffers=0 max-size-bytes=0 ! mux.",
            
            # RTMP Stream (přidán clocksync a avc format pro fixaci DTS)
            f"vtee. ! queue leaky=downstream max-size-time=1000000000 max-size-buffers=0 max-size-bytes=0 ! "
            f"clocksync ! video/x-h264,stream-format=avc,alignment=au ! "
            f"flvmux name=fmux streamable=true ! "
            f"rtmpsink location={self.rtmp_url} async=false sync=false",
            f"atee. ! queue leaky=downstream max-size-time=1000000000 max-size-buffers=0 max-size-bytes=0 ! fmux."
        ]

        pipeline_str = " ".join(parts)
        
        try:
            self.pipeline = Gst.parse_launch(pipeline_str)
            print(">>> Parťák hlásí: Pipeline úspěšně sestavena.")
        except Exception as e:
            print(f">>> Chyba při sestavování: {e}")
            sys.exit(1)

        bus = self.pipeline.get_bus()
        bus.add_signal_watch()
        bus.connect("message", self.on_message)

    def on_message(self, bus, message):
        if message.type == Gst.MessageType.EOS:
            print(">>> Záznam a stream korektně ukončen.")
            self.loop.quit()
        elif message.type == Gst.MessageType.ERROR:
            err, debug = message.parse_error()
            print(f">>> GStreamer Chyba: {err}")
            self.loop.quit()

    def run(self):
        self.pipeline.set_state(Gst.State.PLAYING)
        print(f">>> Nahrávání spuštěno: {self.file_path}")
        print(">>> Pro ukončení stiskni Ctrl+C...")
        try:
            self.loop.run()
        except KeyboardInterrupt:
            self.stop()
        
        self.fix_file()

    def stop(self):
        print("\n>>> Ukončuji (posílám signál EOS do všech větví)...")
        if self.pipeline:
            self.pipeline.send_event(Gst.Event.new_eos())
        GLib.timeout_add(2000, self.loop.quit)

    def fix_file(self):
        """Opraví hlavičky MKV souboru pomocí ffmpeg."""
        if os.path.exists(self.file_path) and os.path.getsize(self.file_path) > 0:
            fixed_path = self.file_path.replace(".mkv", "_fixed.mkv")
            print(f">>> Finalizuji soubor (FFmpeg copy)...")
            cmd = f"ffmpeg -loglevel error -i {self.file_path} -c copy -y {fixed_path} && mv {fixed_path} {self.file_path}"
            try:
                subprocess.run(cmd, shell=True, check=True)
                print(">>> Soubor je připraven a v pořádku.")
            except Exception as e:
                print(f">>> Nepodařilo se finalizovat soubor: {e}")

if __name__ == "__main__":
    recorder = BallaBox()
    signal.signal(signal.SIGINT, lambda s, f: recorder.stop())
    recorder.run()
