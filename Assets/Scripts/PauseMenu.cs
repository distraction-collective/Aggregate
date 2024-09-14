
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.UI;

public class PauseMenu : MonoBehaviour {
  public GameObject pauseCanvas;
  public InputAction inputAction;
  public Button defaultButton;
  private bool playing = true;

  void Awake() {
    inputAction.performed += PauseOrResume;
    inputAction.Enable();
  }

  public void PauseOrResume(InputAction.CallbackContext context) {
    if (playing) {
      Pause();
    } else {
      Resume();
    }
  }

  public void Pause() {
    Time.timeScale = 0f;
    pauseCanvas.SetActive(true);
    Debug.Log(defaultButton.IsActive());
    defaultButton.Select();
    playing = false;
  }
  public void Resume() {
    Time.timeScale = 1f;
    pauseCanvas.SetActive(false);
    playing = true;
  }
}
