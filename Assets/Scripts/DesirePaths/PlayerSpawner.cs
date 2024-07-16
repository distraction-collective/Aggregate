using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using RootMotion.Dynamics;
using UnityEngine.Events;
using UnityEngine.Splines;
using Unity.Mathematics;
using Cinemachine;
using UnityEngine.Rendering.Universal;
using UnityEngine.Rendering;
using UnityEngine.Rendering.HighDefinition;

namespace DesirePaths {
public class PlayerSpawner : MonoBehaviour {
  [SerializeField]
  private Transform _originSpawnPoint;
  [SerializeField]
  PuppetMaster _puppetMaster;
  [SerializeField]
  private float _respawnDelay = 3f;

  [Header("Backtrack cam")]

  [SerializeField]
  private float _backTrackDuration =
      10f; // No matter how long the guts are,
           // its always the same duration by lerp
  [SerializeField]
  private Transform _backTrackElement;
  [SerializeField]
  private CinemachineVirtualCamera _vcam;
  [SerializeField]
  private SplineContainer _spline;

  private float3 _backTrackPosition;
  private float3 _backTrackUp;
  private float3 _backTrackTangent;
  private StarterAssets.ThirdPersonController _thirdPersonController;

  [Header("Rendering")]

  [SerializeField]
  private Camera _camera;
  [SerializeField]
  private Volume _mainPPVolume;
  [SerializeField]
  private VolumeProfile _backtrackPPProfile;
  [SerializeField]
  private VolumeProfile _defaultPPProfile;
  private UniversalAdditionalCameraData _camData;

  public StarterAssets.ThirdPersonController SetThirdPersonController {
    set { _thirdPersonController = value; }
  }
  public UnityEvent OnPlayerRespawnComplete = new UnityEvent();

  public void RespawnPlayer() {
    if (_thirdPersonController == null)
      return;
    StartCoroutine(RespawnRoutine());
  }

  private IEnumerator RespawnRoutine() {
    yield return new WaitForSeconds(_respawnDelay / 2);

    // Respawn
    // TODO restore this
    // _thirdPersonController.transform.position = spawnAt.position;
    // _puppetMaster.Teleport(spawnAt.position, Quaternion.identity, true);
    if (OnPlayerRespawnComplete != null)
      OnPlayerRespawnComplete.Invoke();
  }
}
}
