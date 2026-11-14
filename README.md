# 2D APU for the PYNQ-Z2

A hardware 2D graphics unit written in SystemVerilog for the Zynq-7020 on the
PYNQ-Z2. The ARM processor sends drawing commands over AXI4-Lite, and dedicated
rasterizer engines in the programmable logic draw them into a double-buffered
framebuffer, which is displayed over HDMI.

## Features

- **Four-command instruction set:** `line_draw`, `rect_fill`, `curve_draw`, `text_draw`
- **AXI4-Lite control interface:** each command is a few register writes followed by a start bit
- **Grayscale framebuffer** with a color depth chosen to fit the board's block RAM
- **Double-buffered framebuffer:** draw into one buffer while the other is displayed
- **Integer-only rasterizers:** Bresenham lines and midpoint curves, no multipliers in the stepping logic

## Instruction set

| Command | Operands | Description |
|---|---|---|
| `line_draw` | x0, y0, x1, y1, shade | Line between two points |
| `rect_fill` | x0, y0, x1, y1, shade | Filled rectangle (also used for clear and erase) |
| `curve_draw` | cx, cy, radius, shade | Circle outline |
| `text_draw` | x, y, char, shade | One 8x8 character |
