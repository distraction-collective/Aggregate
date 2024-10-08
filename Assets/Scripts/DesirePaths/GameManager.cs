using RootMotion.Dynamics;
using StarterAssets;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.InputSystem;
using UnityEngine.InputSystem.Utilities;
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
  public GameObject playerStart;
  public PuppetMaster puppetMaster;
  [Header("Player components")]
  public PlayerHealth health;
  public ThirdPersonController player;
  [Header("UX components")]
  public UI.UIManager uiManager;
  public Narration.NarrationManager narrationManager;

  public float autoPauseTimer = 120f;
  private float _timer = 0f;
  private bool _timerActive = false;
  [Header("Input")]
  public InputAction pauseAction;
  public InputAction restartAction;
  public InputAction quitAction;

  public static GameStateEvent OnGameStateChanged = new GameStateEvent();

  public enum GameState { Play, Pause, Init }
  public GameState _currentState = GameState.Init;

  PlayerDeathEvent PlayerDeathEvent => health.PlayerDeathEvent;
  UnityAction UpdateNarration => narrationManager.UpdateNarrationAction;
  private UnityEvent NarrationTrigger =
      new UnityEvent(); // sends a message to the narration manager
                        // to fetch the next line and trigger a narration
                        // event if next line is found

  private bool isPlaying => _currentState == GameState.Play;

  private void Awake() {
    SubscribeToPlayerDeathEvents(true);
    BindNarrationCallbacks(true);
    SubscribeToMenuEvents(true);
    SubscribeToAnyInputEvents(true);

    pauseAction.performed += PauseOrResume;
    pauseAction.Enable();
    restartAction.performed += Restart;
    restartAction.Enable();
    quitAction.performed += Quit;
    quitAction.Enable();

    SetState(GameState.Play);
  }

  private void OnDisable() {
    SubscribeToMenuEvents(false);
    SubscribeToPlayerDeathEvents(false);
    BindNarrationCallbacks(false);
    SubscribeToAnyInputEvents(false);
  }
  /// <summary>
  /// Control the auto-pause timer
  /// </summary>
  /// <param name="b"></param>
  /// <exception cref="NotImplementedException"></exception>
  private void SubscribeToAnyInputEvents(bool b) {
    if (b) {
      InputSystem.onAnyButtonPress.Call(currentAction => { InputDetected(); });
    }
  }

  void InputDetected() {
    // Debug.Log("[GM / AUTO PAUSE]  InputDetected - timer active : " +
    // _timerActive + " / current game state : " + _currentState.ToString());
    if (_timerActive && _currentState != GameState.Pause) {
      ResetTimer();
    }
  }

  void ResetTimer() {
    // Debug.Log("[GM / AUTO PAUSE] Reset autopause timer");
    _timer = 0f;
  }

  void EnableTimer(bool enable) {
    // Debug.Log("[GM / AUTO PAUSE] Toggle autopause timer : " + enable);
    _timerActive = enable;
    if (!enable)
      ResetTimer();
  }

  void Update() {
    if (_timerActive) {
      _timer += Time.deltaTime;
      if (_timer >= autoPauseTimer) {
        EnableTimer(false);
        SetState(GameState.Pause);
      }
    }
  }

  void PauseOrResume(InputAction.CallbackContext context) {
    if (isPlaying) {
      SetState(GameState.Pause);
    } else {
      SetState(GameState.Play);
    }
  }

  void Restart(InputAction.CallbackContext context) {
    Debug.Log("Restarting...");
    player.transform.position = playerStart.transform.position;
    puppetMaster.Teleport(playerStart.transform.position,
                          player.transform.rotation, true);
  }

  void Quit(InputAction.CallbackContext context) {
    Debug.Log("Quitting...");
    Application.Quit();
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
      EnableTimer(true);
      return;
    case GameState.Pause:
      _currentState = newState;
      PauseGame();
      EnableTimer(false);
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
    SubtitlesSwitcher.Show.Invoke(false);
    Time.timeScale = 0f;
  }

  void UnPauseGame() {
    Tools.PostProcessSwitcher.SwitchPP.Invoke(
        DesirePaths.Tools.PostProcessSwitcher.PostProcessType.MENU, false);
    Tools.CameraSwitcher.ToggleCameraMovement.Invoke(true);
    SubtitlesSwitcher.Show.Invoke(true);
    Time.timeScale = 1f;
  }

  void BindNarrationCallbacks(bool bind) {
    if (bind) {
      NarrationTrigger.AddListener(UpdateNarration);
      narrationManager.NarrationUpdated.AddListener(uiManager.DisplaySubs);
    } else {
      NarrationTrigger.RemoveAllListeners();
      narrationManager.NarrationUpdated.RemoveAllListeners();
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

    uiManager.HideNShow(); // Fade
    if (!safe) {
      Cadavers cadavers = GetComponent<Cadavers>();
      cadavers.DepositCadaver();
    }
  }
}

}
