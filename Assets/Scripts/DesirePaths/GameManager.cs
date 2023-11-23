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

    public class GameManager : MonoBehaviour
    {
        [SerializeField] private PlayerSpawner _playerSpawner;
        [SerializeField] private PlayerHealth _playerHealth;
        [SerializeField] private CadaverGutsManager _cadaverManager;
        [SerializeField] private Transform _playerTransform;
        [SerializeField] private StarterAssets.ThirdPersonController _playerThirdPersonController;

        PlayerDeathEvent PlayerDeathEvent => _playerHealth.PlayerDeathEvent;

        private void Awake()
        {
            _playerSpawner.SetThirdPersonController = _playerThirdPersonController;
            SubscribeToPlayerDeathEvents(true);
        }

        private void OnDisable()
        {
            SubscribeToPlayerDeathEvents(false);
        }

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

        void RespawnPlayer(bool safe, Vector3 position)
        {          
            _playerSpawner.RespawnPlayer();
            _playerSpawner.OnPlayerRespawnComplete.AddListener(delegate
            {
                if (!safe)
                {
                    //Deposite cadaver if not on safe space
                    _cadaverManager.DepositCadaverOnPosition(position);
                } //We place only when we're sure camera is not looking, so when resuscitate is called

                _playerSpawner.OnPlayerRespawnComplete.RemoveAllListeners();
                _playerHealth.Resuscitate();
            });
        }
    }
} 

