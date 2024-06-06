using UnityEngine;

public class TerrainColor : MonoBehaviour {
  public GameObject player;
  public Texture2D struggle_map;

  void Start() {
    Color[] pixels = new Color[struggle_map.width * struggle_map.height];
    for (int i = 0; i < pixels.Length; i++) {
      pixels[i] = Color.black;
    }
    struggle_map.SetPixels(pixels);
  }

  void Update() {
    Terrain terrain = Terrain.activeTerrain;
    if (terrain == null) {
      Debug.Log("No active terrain");
    } else {
      float dx = player.transform.position.x - terrain.transform.position.x;
      float dz = player.transform.position.z - terrain.transform.position.z;

      int tx = (int)(dx / terrain.terrainData.size.x * struggle_map.width);
      int tz = (int)(dz / terrain.terrainData.size.z * struggle_map.height);

      Color pixel = struggle_map.GetPixel(tx, tz);
      pixel.r += 5f / 255f;
      struggle_map.SetPixel(tx, tz, pixel);
      struggle_map.Apply();
    }
  }
}
