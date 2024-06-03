using UnityEngine;

// TODO add tooltips
// TODO encode data into RGBA

public class Struggle : MonoBehaviour {

  public GameObject player;
  public GameObject terrain;
  public Texture2D struggle_map;

  void Start() {
    Color[] pixels = new Color[struggle_map.width * struggle_map.height];
    for (int i = 0; i < pixels.Length; i++) {
      pixels[i] = Color.black;
    }
    struggle_map.SetPixels(pixels);
  }

  void Update() {
    Renderer tr = terrain.GetComponent<Renderer>();

    float txmin = tr.bounds.min.x;
    float txmax = tr.bounds.max.x;
    float x = player.transform.position.x;
    int tx = (int)(struggle_map.width * (x - txmin) / (txmax - txmin));

    float tzmin = tr.bounds.min.z;
    float tzmax = tr.bounds.max.z;
    float z = player.transform.position.z;
    int tz = (int)(struggle_map.height * (z - tzmin) / (tzmax - tzmin));

    struggle_map.SetPixel(tx, tz, Color.white);
    struggle_map.Apply();
  }
}
