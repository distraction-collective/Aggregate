
using System;
using DesirePaths;
using DesirePaths.Tools;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.UI;
using UnityEngine.Localization.Settings;

public class PauseMenu : MonoBehaviour {
  public GameObject pauseCanvas;
  //public InputAction inputAction;
  public Button defaultButton;
  //private bool playing = true;

  void OnEnable() {
    GameManager.OnGameStateChanged.AddListener(GameStateChanged);
  }

  private void GameStateChanged(GameManager.GameState newState)
  {
    switch (newState)
    {
      case GameManager.GameState.Pause:
        Pause();
        return;
      case GameManager.GameState.Play:
        Resume();
        return;
    }
  }

  private void OnDisable()
  {
    GameManager.OnGameStateChanged.RemoveListener(GameStateChanged);
  }

  /* Moved up to GameManager to handle game play state higher in the game architecture
  public void PauseOrResume(InputAction.CallbackContext context) {
    if (playing) {
      Pause();
    } else {
      Resume();
    }
  }
  */

  public void Pause() {
    pauseCanvas.SetActive(true);
    //Debug.Log(defaultButton.IsActive());
    defaultButton.Select();
    //playing = false;
  }
  public void Resume() {
    pauseCanvas.SetActive(false);
    //playing = true;
  }

  public void SetLanguageEn() {
    LocalizationSettings.SelectedLocale =
        LocalizationSettings.AvailableLocales.GetLocale("en");
  }

  public void SetLanguageFr() {
    LocalizationSettings.SelectedLocale =
        LocalizationSettings.AvailableLocales.GetLocale("fr");
  }

  public void Quit() { Application.Quit(); }
}
