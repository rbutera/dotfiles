#!/usr/bin/env python3
# set_clipboard.py
import sys
import pyperclip

input_data = sys.stdin.read()
pyperclip.copy(input_data)
