### How to add powerlines

Draw a spline defining the path of the powerlines. One pylon will be spawned per point. The spline itself won't be rendered.

![image](https://github.com/user-attachments/assets/1470ddba-8578-47b3-ae6f-fa711d01facc)

Add the `Powerlines.cs` script and define the pylon prefab as well as the cable material. You're free to chose whatever pylon prefab you like but make sure that it has `attach0`, ..., `attach10` empties. These will be used to compute the cable curves.

![image](https://github.com/user-attachments/assets/24f4a0ae-1009-4277-87aa-594cccfc1735)

![image](https://github.com/user-attachments/assets/ede699d6-db32-46c0-be56-ab28c9d5d56d)

There is a custom "Spawn Pylons at Knots" context menu action. Click it.

![image](https://github.com/user-attachments/assets/2b919c90-2016-420f-8182-3725c6ba4aba)

This should create pylons and cables.

![image](https://github.com/user-attachments/assets/fc12fbc9-0419-45d3-9ee9-80f69de048cb)
