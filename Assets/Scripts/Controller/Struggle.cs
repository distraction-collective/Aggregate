using UnityEngine;

// TODO add tooltips
// TODO encode data into RGBA

public class Struggle : MonoBehaviour {

  public GameObject player;
  public Texture2D struggle_map;
  public float world_size = 64;

  void Start() {
    Color[] pixels = new Color[struggle_map.width * struggle_map.height];
    for (int i = 0; i < pixels.Length; i++) {
      pixels[i] = Color.black;
    }
    struggle_map.SetPixels(pixels);
  }

  void Update() {
    Vector3 normalized_position = player.transform.position / world_size;
    int tx = (int)(struggle_map.width * (normalized_position.x + 0.5f));
    int ty = (int)(struggle_map.height * (normalized_position.z + 0.5f));
    struggle_map.SetPixel(tx, ty, Color.white);
    struggle_map.Apply();
  }
}
