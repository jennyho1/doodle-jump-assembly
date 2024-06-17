# Doodle Jump Game 

Made with Assembly and Mars MIPS
This classic doodle jump game features 4 different types of platforms: Green (normal block), Blue (bouncy block), Orange (fragile block), and Purple (moving block). It also contains opponents that can kill the Doodler, shooting mechanic to eliminate opponent and also sound effects.

## Getting Started

1. Download Mars MIPS simulator [here](https://courses.missouristate.edu/kenvollmar/mars/)
2. Clone the repo
   ```
   git clone https://github.com/jennyho1/doodle-jump-assembly
   ```
3. Open Mars, go to file > open doodlejump.s
4. Configure bitmap display
    1. Go to Tools > Bitmap Display
    2. ```
       - Unit width in pixels: 8
       - Unit height in pixels: 8
       - Display width in pixels: 256
       - Display height in pixels: 256
       - Base Address for Display: 0x10008000 ($gp)
       ```
   3. Connect to MIPS
5. Go to Tools > Keyboard and Display MMIO Simulator and connect to MIPS
6. To run game:
    1. Run > Assemble (or F3)
    2. Run > Go (or F5)
  
### Notes:
- Make sure your keyboard input are being received in the Keyboard simulator text area.
- Use `j` and `k` to move left and right respectively
- Use `f` to shoot
