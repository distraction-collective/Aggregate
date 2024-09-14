
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.UI;
using UnityEngine.Localization.Settings;

public class PauseMenu : MonoBehaviour {
  public GameObject pauseCanvas;
  public InputAction inputAction;
  public Button defaultButton;
  private bool playing = true;

  void OnEnable() {
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

  public void SetLanguageEn() {
    LocalizationSettings.SelectedLocale =
        LocalizationSettings.AvailableLocales.GetLocale("en");
  }

  public void SetLanguageFr() {
    LocalizationSettings.SelectedLocale =
        LocalizationSettings.AvailableLocales.GetLocale("fr");
  }
}
