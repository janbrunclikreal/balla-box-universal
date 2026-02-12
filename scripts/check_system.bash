#!/bin/bash
echo ">>> Kontrola Balla Boxu..."
gst-inspect-1.0 mpph264enc > /dev/null && echo "[ OK ] MPP Enkodér nalezen" || echo "[ ERROR ] MPP Enkodér chybí"
systemctl --user is-active pulseaudio.service > /dev/null && echo "[ OK ] Audio běží" || echo "[ ERROR ] Audio nefunguje"
