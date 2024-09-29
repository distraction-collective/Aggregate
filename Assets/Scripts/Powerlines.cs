using UnityEngine;
using UnityEngine.Splines;

public class Powerlines : MonoBehaviour {
  private SplineContainer splineContainer => GetComponent<SplineContainer>();
  public GameObject tipPrefab;
  public GameObject pylonPrefab;
  public Material cableMaterial;
  public int cableResolution = 20;
  public float cableFallHeight = 3f;

  [ContextMenu("Spawn Pylons at Knots")]
  public void SpawnPrefabsAtKnots() {
    // Clear existing
    while (transform.childCount > 0) {
      DestroyImmediate(transform.GetChild(0).gameObject);
    }

    // Spawns pylons
    Spline path = splineContainer.Splines[0];
    GameObject[] pylons = new GameObject[path.Count];
    for (int i = 0; i < path.Count; i++) {
      BezierKnot knot = path[i];
      bool is_tip = i == 0 || i == (path.Count - 1);
      pylons[i] = Instantiate(is_tip ? tipPrefab : pylonPrefab, transform);
      pylons[i].name = $"pylon{i}";
      pylons[i].transform.position =
          splineContainer.transform.TransformPoint(knot.Position);
      // aligned with curve, but upright
      pylons[i].transform.rotation = Quaternion.Euler(
          0f,
          (splineContainer.transform.rotation * knot.Rotation).eulerAngles.y,
          0f);
    }

    // Spawns cables
    for (int i = 0; i < pylons.Length - 1; i++) {
      GameObject pylonA = pylons[i];
      GameObject pylonB = pylons[i + 1];

      // Iterates over attach points and draw a cable between them
      // Make sure to have empties named attach0,...,attach9 in your pylon
      // prefab!
      for (int j = 0; j < 10; j++) {
        Transform start = pylonA.transform.Find($"attach{j}");
        Transform end = pylonB.transform.Find($"attach{j}");

        GameObject cable = new GameObject($"cable{i}.{j}");
        cable.transform.SetParent(transform, false);

        LineRenderer lineRenderer = cable.AddComponent<LineRenderer>();
        lineRenderer.startWidth = .1f;
        lineRenderer.endWidth = .1f;
        lineRenderer.material = cableMaterial;
        lineRenderer.positionCount = cableResolution;
        for (int k = 0; k < cableResolution; k++) {
          float t = (float)k / (cableResolution - 1);
          Vector3 point = Vector3.Lerp(start.position, end.position, t) +
                          cableFallHeight * Vector3.up * 4f * t * (t - 1);
          lineRenderer.SetPosition(k, point);
        }
      }
    }
  }
}