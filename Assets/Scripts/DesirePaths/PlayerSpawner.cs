using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using RootMotion.Dynamics;
using UnityEngine.Events;

namespace DesirePaths
{
    public class PlayerSpawner : MonoBehaviour
    {
        [SerializeField] private Transform _originSpawnPoint;
        [SerializeField] PuppetMaster _puppetMaster;
        [SerializeField] private float _respawnDelay = 3f;
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
            yield return new WaitForSeconds(_respawnDelay);
            _thirdPersonController.transform.position = _originSpawnPoint.transform.position;
            _puppetMaster.Teleport(_originSpawnPoint.transform.position, Quaternion.identity, true);
            if(OnPlayerRespawnComplete != null) OnPlayerRespawnComplete.Invoke();
        }
    }
}

