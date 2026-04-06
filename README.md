# Weekend Shaders

These are little shader artworks I do on the weekend.

## 🗓️ Shader Logs

**Sunday, April 5 - OBJ Rendering**

I wrote a simple program that takes a OBJ file and creates a shader program that renders the geometry. Examples from a sample dataset are provided in the file.

🔗 [obj_renderer.py](https://github.com/MatthewAndreTaylor/WeekendShaders/blob/main/obj_renderer.py)

```sh
python obj_renderer.py input.obj
```

https://github.com/user-attachments/assets/3318981e-8b7e-44fc-9b33-76ff76425568

---

**Sunday, August 24 - Infinite Tower of Lire**

I wrote a program that renders an infinite stack of blocks at a harmonic offset. The effect resembles a waterfall of blocks being stacked on top of each other. Inspired by a math video I was watching on YouTube about the subject.

🔗 [tower_of_lire.glsl](https://github.com/MatthewAndreTaylor/WeekendShaders/blob/main/tower_of_lire.glsl)

[tower_of_lire.webm](https://github.com/user-attachments/assets/25f83e2b-c0e8-4edd-b63a-71329e65d39d)

---

**Saturday, August 3 - SDF Tunnel**

I wrote a program that renders a tunnel full of hexagons inspired by an old game I used to play called Run. The curve of the tunnel can be adjusted using the mouse.

🔗 [tunnel.glsl](https://github.com/MatthewAndreTaylor/WeekendShaders/blob/main/tunnel.glsl)

[tunnel.webm](https://github.com/user-attachments/assets/a437a3bf-5350-47d4-a946-97c230e265ef)

---

**Saturday, July 6 - SVG to Shader Compiler**

I wrote a program which compiles a svg to a shader. Currently the program is very simple and does not do any optimization.

🔗 [svg_to_shader.py](https://github.com/MatthewAndreTaylor/WeekendShaders/blob/main/svg_to_shader.py)

```sh
python svg_to_shader.py input.svg
```

![canoe_raster](https://github.com/user-attachments/assets/607a03c1-8d02-46f4-8f19-aff368737e87)

<details>
  <summary>example input</summary>
  
  ![example_input](https://github.com/user-attachments/assets/e9ab1bcb-3914-4b96-829f-c4e96b0411c7)
</details>

---

**Saturday, June 27 – Katana**

I drew a katana with simple shapes and gave the blade a gradient. It would be cool to animate in the future.

🔗 [katana.glsl](https://github.com/MatthewAndreTaylor/WeekendShaders/blob/main/katana.glsl)

![katana](https://github.com/user-attachments/assets/db0653b9-9176-4ac6-af09-d7fa8f57a4d6)

---

**Sunday, June 15 – Neural Network Visualization**

More procedural character movement added a wiggle and jumping movement.

🔗 [showman.glsl](https://github.com/MatthewAndreTaylor/WeekendShaders/blob/main/showman.glsl)

[showman.webm](https://github.com/user-attachments/assets/f95e20ea-9f28-490d-9492-0534a8be8937)

---

I wanted to write a program to visualize a fully connected neural network.
I used a different color gradient for each network connection in combination with each layer.

🔗 [neuralnet.glsl](https://github.com/MatthewAndreTaylor/WeekendShaders/blob/main/neuralnet.glsl)

[neuralnet.webm](https://github.com/user-attachments/assets/7253f8cc-309c-4c05-9867-ca5c5dc6da35)

---

**Sunday, June 15 – Voxel Raymarching Chicken**

I used voxels to design a chicken and rendered it using raymarching.

🔗 [voxel_chicken.glsl](https://github.com/MatthewAndreTaylor/WeekendShaders/blob/main/voxel_chicken.glsl)

[voxel_chicken.webm](https://github.com/user-attachments/assets/1a6db951-8e47-4310-bad0-a5b190888416)

---

**Sunday, June 1 – Procedural Snake Animation**

I animated a snake procedurally. The snake body segments follow a smooth trajectory.

🔗 [snake.glsl](https://github.com/MatthewAndreTaylor/WeekendShaders/blob/main/snake.glsl)

[snake_long.webm](https://github.com/user-attachments/assets/f2fa6d6e-f0ec-4947-8a51-ce6696ea1ad7)

<details>
  <summary>demo 2</summary>
  
  [snake_short.webm](https://github.com/user-attachments/assets/c84dd634-b0e2-4e40-9562-8fbe10534ff7)
</details>


---

**Saturday, May 24 – Grass Movement**

I simulated a bunch of little grass pieces being moved by the wind. I liked the color palette I used.

🔗 [grass.glsl](https://github.com/MatthewAndreTaylor/WeekendShaders/blob/main/grass.glsl)

[grass.webm](https://github.com/user-attachments/assets/e80cddb7-beaa-44fe-9606-65029823abd4)

---

**Friday, May 23 – Ray Marching Letters**

I drew the first letter of my name "M" using Ray Marching and a custom signed distance function (SDF).
In future work I could try to render more complex [tetrahedra](https://developer.nvidia.com/gpugems/gpugems3/part-v-physics-simulation/chapter-34-signed-distance-fields-using-single-pass-gpu)

🔗 [sdfM.glsl](https://github.com/MatthewAndreTaylor/WeekendShaders/blob/main/sdfM.glsl)

[sdfM.webm](https://github.com/user-attachments/assets/fe235c37-2d4c-49d2-aad9-91260261ccad)

---

**Sunday, May 18 – Procedural Trees**

I wanted to see if I could draw procedurally generated 2d trees as a shader. I had seen some examples, but was wondering if I could do something similar to the recursive approach inside a shader.

🔗 [procedural_trees.glsl](https://github.com/MatthewAndreTaylor/WeekendShaders/blob/main/procedural_trees.glsl)

<img src="https://github.com/user-attachments/assets/f71c893b-c24c-4b42-9c79-8d5250f6a7c8" alt="tree_0" width="300" />  
<img src="https://github.com/user-attachments/assets/e5bd821f-e9cd-4f0f-8d82-98b79512092c" alt="tree_1" width="300" />

---

**Sunday, May 11 – Starfield**

I turned my old highschool project below into a shader.

🔗 [starfield java](https://github.com/MatthewAndreTaylor/Java-Resources/tree/main/StarFeild/src/starfeild)
🔗 [starfield.glsl](https://github.com/MatthewAndreTaylor/WeekendShaders/blob/main/starfield.glsl)

[starfield.webm](https://github.com/user-attachments/assets/baef4be8-d1e7-4032-bf8b-70ef3d1dccdf)

---
