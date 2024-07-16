using UnityEngine;

public class TerrainColor : MonoBehaviour {
  [Tooltip("Player game object, should probably be MediumRetopoRigged")]
  public GameObject player;

  [Tooltip(
      "Struggle map writable texture used elsewhere, for example in the terrain shader to change ground color based on walked paths")]
  public Texture2D struggle_map;

  [Tooltip("How strong does walking on brambles clears them out")]
  [Range(0f, 1f)]
  public float clear_force = 1f;

  void Start() {
    Color[] pixels = new Color[struggle_map.width * struggle_map.height];
    for (int i = 0; i < pixels.Length; i++) {
      pixels[i] = Color.black;
    }
    struggle_map.SetPixels(pixels);
  }

  void Update() {
    (int u, int v) = GetStruggleUV();
    Color pixel = struggle_map.GetPixel(u, v);
    pixel.r += clear_force;
    struggle_map.SetPixel(u, v, pixel);
    struggle_map.Apply();
  }

  private(int, int) GetStruggleUV() {
    Terrain terrain = Terrain.activeTerrain;
    float dx = player.transform.position.x - terrain.transform.position.x;
    float dz = player.transform.position.z - terrain.transform.position.z;
    int u = (int)(dx / terrain.terrainData.size.x * struggle_map.width);
    int v = (int)(dz / terrain.terrainData.size.z * struggle_map.height);
    return (u, v);
  }
}
