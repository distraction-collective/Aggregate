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

namespace DesirePaths
{
    public class PlayerSpawner : MonoBehaviour
    {
        [SerializeField] private Transform _originSpawnPoint;
        [SerializeField] PuppetMaster _puppetMaster;
        [SerializeField] private float _respawnDelay = 3f;

        private UX.CameraBacktrack cameraBacktrack => GetComponent<UX.CameraBacktrack>();

        [Header("Backtrack cam")]

        [SerializeField] private float _backTrackDuration = 10f; //No matter how long the guts are, its always the same duration by lerp
        [SerializeField] private Transform _backTrackElement;
        [SerializeField] private CinemachineVirtualCamera _vcam;
        [SerializeField] private SplineContainer _spline;

        private StarterAssets.ThirdPersonController _thirdPersonController;

        public StarterAssets.ThirdPersonController SetThirdPersonController
        {
            set
            {
                _thirdPersonController = value;
            }
        }
        public UnityEvent OnPlayerRespawnComplete = new UnityEvent();

        public void RespawnPlayer()
        {
            if (_thirdPersonController == null) return;
            StartCoroutine(RespawnRoutine());
        }

        private IEnumerator RespawnRoutine()
        {
            yield return new WaitForSeconds(_respawnDelay / 2); //Before we start backtrack
            cameraBacktrack.OnBacktrackComplete.AddListener(delegate
            {
                cameraBacktrack.OnBacktrackComplete.RemoveAllListeners();
                //Respawn
                _thirdPersonController.transform.position = _originSpawnPoint.transform.position;
                _puppetMaster.Teleport(_originSpawnPoint.transform.position, Quaternion.identity, true);
                if (OnPlayerRespawnComplete != null) OnPlayerRespawnComplete.Invoke();
            });
            cameraBacktrack.Backtrack(_respawnDelay / 2);
        }
    }
}

