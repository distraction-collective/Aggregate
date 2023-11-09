using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AngelBillboard : MonoBehaviour {
  Camera mainCamera;
  void Start() { mainCamera = Camera.main; }
  void LateUpdate() {
    transform.LookAt(mainCamera.transform);
    transform.Rotate(90, 0, 0);
  }
}
