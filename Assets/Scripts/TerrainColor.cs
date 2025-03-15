using System.IO;
using System.Linq;
using UnityEngine;

public class TerrainColor : MonoBehaviour {
  [Tooltip("Player game object, should probably be MediumRetopoRigged")]
  public GameObject player;

  [Tooltip("Struggle map writable texture used elsewhere, for example in the terrain shader to change ground color based on walked paths")]
  public Texture2D struggle_map;

  [Tooltip("Texture externe dont le contenu sera intégré dans la couche verte de la struggle map")]
  public Texture2D externalTexture;

  [Tooltip("How strong does walking on brambles clears them out")]
  [Range(0f, 1f)]
  public float clear_force = 1f;

  private string path = Path.Combine(Application.dataPath, "Scripts/Controller/struggle_map_with_landmarks.png");

  void Start() {
    if (!File.Exists(path)) {
      Debug.LogError($"File {path} not found. Make sure you compute the safe landmarks!");
      return;
    }
    byte[] fileData = File.ReadAllBytes(path);
    bool ok = struggle_map.LoadImage(fileData);
    if (!ok) {
      Debug.LogError($"Could not load cached safe landmarks. Computing now, this might take ~10s. For faster game startup, investigate why {path} was not loaded into the struggle_map texture.");
      ComputeSafeLandmarks();
    }

    // Intégration de la texture externe dans la struggle map
    MergeExternalTexture();

    // Améliorer le rendu en adoucissant le filtrage
    struggle_map.filterMode = FilterMode.Bilinear;
    struggle_map.wrapMode = TextureWrapMode.Clamp;
    struggle_map.anisoLevel = 1;
    struggle_map.Apply();
  }

  void Update() {
    (int u, int v) = GetStruggleUV();
    Color pixel = struggle_map.GetPixel(u, v);
    pixel.r += clear_force;
    struggle_map.SetPixel(u, v, pixel);
    struggle_map.Apply();
  }

  private (int, int) GetStruggleUV() {
    Terrain terrain = Terrain.activeTerrain;
    float dx = player.transform.position.x - terrain.transform.position.x;
    float dz = player.transform.position.z - terrain.transform.position.z;
    int u = (int)(dx / terrain.terrainData.size.x * struggle_map.width);
    int v = (int)(dz / terrain.terrainData.size.z * struggle_map.height);
    return (u, v);
  }

  private void ComputeSafeLandmarks() {
    Color[] pixels = struggle_map.GetPixels();
    int size = struggle_map.width;
    for (int i = 0; i < pixels.Length; i++) {
      int u = i % size;
      int v = i / size;
      float dx = (float)u / size * Terrain.activeTerrain.terrainData.size.x;
      float dz = (float)v / size * Terrain.activeTerrain.terrainData.size.z;
      RaycastHit[] hits = Physics.RaycastAll(
          Terrain.activeTerrain.transform.position + new Vector3(dx, 1000f, dz),
          Vector3.down, Mathf.Infinity);
      bool over_safe = hits.Any(hit => hit.collider.CompareTag("Safe"));
      pixels[i] = over_safe ? Color.blue : Color.black;
    }
    struggle_map.SetPixels(pixels);
    struggle_map.Apply();
  }

  /// <summary>
  /// Fusionne le contenu de la texture externe dans le canal vert de la struggle map.
  /// </summary>
  private void MergeExternalTexture() {
    if (externalTexture != null) {
      if (externalTexture.width == struggle_map.width && externalTexture.height == struggle_map.height) {
        Color[] strugglePixels = struggle_map.GetPixels();
        Color[] externalPixels = externalTexture.GetPixels();
        for (int i = 0; i < strugglePixels.Length; i++) {
          // Par exemple, on prend la composante rouge de la texture externe et on l'assigne au canal vert de la struggle map.
          strugglePixels[i].g = externalPixels[i].r;
        }
        struggle_map.SetPixels(strugglePixels);
        struggle_map.Apply();
      } else {
        Debug.LogWarning("Les dimensions de externalTexture ne correspondent pas à celles de struggle_map.");
      }
    }
  }

  [ContextMenu("Compute and save safe landmarks")]
  public void ComputeAndSaveSafeLandmarks() {
    Debug.Log("Computing safe landmarks...");
    ComputeSafeLandmarks();
    // Fusionner la texture externe avant la sauvegarde pour que les pixels ajoutés soient inclus
    MergeExternalTexture();
    byte[] fileData = struggle_map.EncodeToPNG();
    File.WriteAllBytes(path, fileData);
    Debug.Log($"Saved safe landmarks to {path}");
  }
}
