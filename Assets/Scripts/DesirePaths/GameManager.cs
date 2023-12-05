using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

namespace DesirePaths
{
    /// <summary>
    /// Called when the player dies somewhere. Takes two arguments : bool (is dead in safe zone) and position (where the player died)
    /// </summary>
    [System.Serializable]
    public class PlayerDeathEvent : UnityEvent<bool, Vector3>
    {
    }

    /// <summary>
    /// Used by landmarks. Has a landmark event enum as argument.
    /// </summary>
    [System.Serializable]
    public class LandmarkEvent : UnityEvent<Landmarks.LandmarkManager.LandmarkEvents>
    {
    }

    public class GameManager : MonoBehaviour
    {
        [Header("Player components")]        
        [SerializeField] private PlayerHealth _playerHealth;
        [SerializeField] private Transform _playerTransform;
        [SerializeField] private StarterAssets.ThirdPersonController _playerThirdPersonController;
        [Header("Gameplay components")]
        [SerializeField] private PlayerSpawner _playerSpawner;
        [SerializeField] private CadaverGutsManager _cadaverManager;
        [SerializeField] private Landmarks.LandmarkManager _landmarkManager;

        PlayerDeathEvent PlayerDeathEvent => _playerHealth.PlayerDeathEvent;
        LandmarkEvent LandmarkTriggerEvent => _landmarkManager.OnLandmarkTriggered;
        LandmarkEvent LandmarksCompleted => _landmarkManager.OnLandmarkCompletion;

        private void Awake()
        {
            _playerSpawner.SetThirdPersonController = _playerThirdPersonController;
            SubscribeToPlayerDeathEvents(true);
            SubscribeToLandmarkEvents(true);
        }

        private void OnDisable()
        {
            SubscribeToPlayerDeathEvents(false);
            SubscribeToLandmarkEvents(false);
        }

        #region Landmarks
        void SubscribeToLandmarkEvents(bool subscribe)
        {
            if (subscribe)
            {
                LandmarkTriggerEvent.AddListener(LandmarkTriggered);
                LandmarksCompleted.AddListener(LandmarksComplete);
            }
            else
            {
                LandmarkTriggerEvent.RemoveAllListeners();
                LandmarksCompleted.RemoveAllListeners();
            }
        }

        void LandmarksComplete(Landmarks.LandmarkManager.LandmarkEvents e)
        {
            switch (e)
            {
                case Landmarks.LandmarkManager.LandmarkEvents.ALL_PILLARS_ACTIVATED:
                    Debug.Log("[Game manager / landmarks] ALL PILLARS COMPLETE");
                    break;
                case Landmarks.LandmarkManager.LandmarkEvents.ALL_LANDMARKS_ENTERED:
                    Debug.Log("[Game manager / landmarks] ALL GENERIC LANDMARKS VISITED");
                    break;
                default:
                    return;
            }
        }

        void LandmarkTriggered(Landmarks.LandmarkManager.LandmarkEvents e) {
            switch(e)
            {
                case Landmarks.LandmarkManager.LandmarkEvents.PILLAR_ACTIVATED:
                    Debug.Log("[Game manager / landmarks] pillar activated");
                    break;
                case Landmarks.LandmarkManager.LandmarkEvents.LANDMARK_ENTERED:
                    Debug.Log("[Game manager / landmarks] generic landmark entered");
                    break;
                default:
                    return;
            }
        }
        #endregion

        #region Player Death / Respawn
        private void SubscribeToPlayerDeathEvents(bool subscribe)
        {
            if(subscribe)
            {
                PlayerDeathEvent.AddListener(RespawnPlayer);
            } else
            {
                PlayerDeathEvent.RemoveAllListeners();
            }            
        }

        /// <summary>
        /// TODO : yield until game state allows for execution
        /// 
        /// </summary>
        /// <param name="safe"></param>
        /// <param name="position"></param>
        void RespawnPlayer(bool safe, Vector3 position)
        {
            //du coup dans ta note rajoute le fait que je dois deposer les viscères avant de faire le respawn, et le deposite cadaver - si on veut faire une animation qui backtrack tout notre chemin
            _playerSpawner.OnPlayerRespawnComplete.AddListener(delegate
            {
                _playerSpawner.OnPlayerRespawnComplete.RemoveAllListeners();
                if (!safe)
                {
                    //Deposite cadaver if not on safe space
                    _cadaverManager.DepositCadaverOnPosition(position);
                } //We place only when we're sure camera is not looking, so when resuscitate is call                
                _playerHealth.Resuscitate();
            });
            _playerSpawner.RespawnPlayer();            
        }
        #endregion
    }

}

