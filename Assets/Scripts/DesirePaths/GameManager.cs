using UnityEngine;
using UnityEngine.Events;
using UnityEngine.InputSystem;
using UnityEngine.SceneManagement;

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
  [Header("UX components")]
  [SerializeField]
  private UI.UIManager _uiManager;
  [SerializeField]
  private Narration.NarrationManager _narrationManager;
  [Header("Input")]
  public InputAction pauseAction;
  public InputAction restartAction;
  public InputAction quitAction;

  public static GameStateEvent OnGameStateChanged = new GameStateEvent();

  public enum GameState { Play, Pause, Init }
  [SerializeField]
  private GameState _currentState = GameState.Init;

  PlayerDeathEvent PlayerDeathEvent => _playerHealth.PlayerDeathEvent;
  UnityAction UpdateNarration => _narrationManager.UpdateNarrationAction;
  private UnityEvent NarrationTrigger =
      new UnityEvent(); // sends a message to the narration manager
                        // to fetch the next line and trigger a narration
                        // event if next line is found

  private bool isPlaying => _currentState == GameState.Play;

  private void Awake() {
    SubscribeToPlayerDeathEvents(true);
    BindNarrationCallbacks(true);
    SubscribeToMenuEvents(true);

    pauseAction.performed += PauseOrResume;
    pauseAction.Enable();
    restartAction.performed += Restart;
    restartAction.Enable();
    quitAction.performed += Quit;
    quitAction.Enable();

    SetState(GameState.Play);
  }

  void PauseOrResume(InputAction.CallbackContext context) {
    if (isPlaying) {
      SetState(GameState.Pause);
    } else {
      SetState(GameState.Play);
    }
  }

  void Restart(InputAction.CallbackContext context) {
    SceneManager.LoadScene("Main");
  }

  void Quit(InputAction.CallbackContext context) { Application.Quit(); }

  private void OnDisable() {
    SubscribeToMenuEvents(false);
    SubscribeToPlayerDeathEvents(false);
    BindNarrationCallbacks(false);
  }

  void SetState(GameState newState) {
    if (newState == _currentState)
      return;
    if (OnGameStateChanged != null)
      OnGameStateChanged.Invoke(newState);
    switch (newState) {
    case GameState.Play:
      if (_currentState == GameState.Pause)
        UnPauseGame();
      _currentState = newState;
      return;
    case GameState.Pause:
      _currentState = newState;
      PauseGame();
      return;
    case GameState.Init:
      _currentState = newState;
      return;
    }
  }

  void PauseGame() {
    Tools.PostProcessSwitcher.SwitchPP.Invoke(
        DesirePaths.Tools.PostProcessSwitcher.PostProcessType.MENU, true);
    Tools.CameraSwitcher.ToggleCameraMovement.Invoke(false);
    Time.timeScale = 0f;
  }

  void UnPauseGame() {
    Tools.PostProcessSwitcher.SwitchPP.Invoke(
        DesirePaths.Tools.PostProcessSwitcher.PostProcessType.MENU, false);
    Tools.CameraSwitcher.ToggleCameraMovement.Invoke(true);
    Time.timeScale = 1f;
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

  private void SubscribeToMenuEvents(bool subscribe) {
    if (subscribe) {
      PauseMenu.OnResumeButtonPressed.AddListener(delegate { UnPauseGame(); });
    } else {
      PauseMenu.OnResumeButtonPressed.RemoveAllListeners();
    }
  }

  void RespawnPlayer(bool safe, Vector3 position) {

    _uiManager.HideNShow(); // Fade
    if (!safe) {
      Cadavers cadavers = GetComponent<Cadavers>();
      cadavers.DepositCadaver();
    }
  }
}

}
