using UnityEngine;
using UnityEngine.Events;

namespace DesirePaths {
/// <summary>
/// Called when the player dies somewhere. Takes two arguments : bool (is dead
/// in safe zone) and position (where the player died)
/// </summary>
[System.Serializable]
public class PlayerDeathEvent : UnityEvent<bool, Vector3> {}

/// <summary>
/// Used for callbacks responding to game state changes
/// </summary>
public class GameStateEvent : UnityEvent<GameManager.GameState> {}

/// <summary>
/// Used for callbacks responding to narration update changes
/// </summary>
public class NarrationUpdateEvent : UnityEvent<string> {}

public class GameManager : MonoBehaviour {
  [Header("Player components")]
  [SerializeField]
  private PlayerHealth _playerHealth;
  [SerializeField]
  private Transform _playerTransform;
  [SerializeField]
  private StarterAssets.ThirdPersonController _playerThirdPersonController;
  [Header("Gameplay components")]
  [SerializeField]
  private PlayerSpawner _playerSpawner;
  [SerializeField]
  private CadaverGutsManager _cadaverManager;
  [Header("UX components")]
  [SerializeField]
  private UI.UIManager _uiManager;
  [SerializeField]
  private Narration.NarrationManager _narrationManager;

  public static GameStateEvent OnGameStateChanged;

  public enum GameState { Play, Pause, Init }
  private GameState _currentState = GameState.Init;

  PlayerDeathEvent PlayerDeathEvent => _playerHealth.PlayerDeathEvent;
  UnityAction UpdateNarration => _narrationManager.UpdateNarrationAction;
  private UnityEvent NarrationTrigger =
      new UnityEvent(); // sends a message to the narration manager
                        // to fetch the next line and trigger a narration
                        // event if next line is found

  private void Awake() {
    _playerSpawner.SetThirdPersonController = _playerThirdPersonController;
    SubscribeToPlayerDeathEvents(true);
    BindNarrationCallbacks(true);
    SetState(GameState.Play);
  }

  private void OnDisable() {
    SubscribeToPlayerDeathEvents(false);
    BindNarrationCallbacks(false);
  }

  void SetState(GameState newState) {
    if (newState == _currentState)
      return;
    _currentState = newState;
    if (OnGameStateChanged != null)
      OnGameStateChanged.Invoke(newState);
    switch (newState) {
    case GameState.Play:
      return;
    case GameState.Pause:
      return;
    case GameState.Init:
      return;
    }
  }

  void BindNarrationCallbacks(bool bind) {
    if (bind) {
      NarrationTrigger.AddListener(UpdateNarration);
      _narrationManager.NarrationUpdated.AddListener(_uiManager.DisplaySubs);
    } else {
      NarrationTrigger.RemoveAllListeners();
      _narrationManager.NarrationUpdated.RemoveAllListeners();
    }
  }

  private void SubscribeToPlayerDeathEvents(bool subscribe) {
    if (subscribe) {
      PlayerDeathEvent.AddListener(RespawnPlayer);
    } else {
      PlayerDeathEvent.RemoveAllListeners();
    }
  }

  void RespawnPlayer(bool safe, Vector3 position) {

    _uiManager.HideNShow(); // Fade
    if (!safe) {
      // TODO restore this
      // Deposite cadaver if not on safe space
      // _cadaverManager.DepositCadaverOnPosition(position);
    }

    _playerSpawner.OnPlayerRespawnComplete.AddListener(delegate {
      _playerSpawner.OnPlayerRespawnComplete.RemoveAllListeners();
      // We place only when we're sure camera is not looking, so when
      // resuscitate is call
      _playerHealth.Resuscitate();
    });
    _playerSpawner.RespawnPlayer();
  }
}

}
