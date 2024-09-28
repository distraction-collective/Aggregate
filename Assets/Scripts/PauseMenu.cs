
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
  [SerializeField] private Sprite[] deactivatedLanguageSprites = new Sprite[2];
  [SerializeField] private Sprite[] activatedLanguageSprites = new Sprite[2];
  [SerializeField] private Image[] languageDisplays = new Image[2];

  private bool isEnglishSelected
  {
    get
    {
      return LocalizationSettings.SelectedLocale.ToString() == "English (en)";
    }
  }

  void OnEnable() {
    GameManager.OnGameStateChanged.AddListener(GameStateChanged);
    InitLanguageDisplay();
  }

  void OnDisable()
  {
    GameManager.OnGameStateChanged.RemoveListener(GameStateChanged);
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

  public void Pause() {
    pauseCanvas.SetActive(true);
    defaultButton.Select();
    //InitLanguageDisplay();
  }
  public void Resume() {
    pauseCanvas.SetActive(false);
  }
  
  private void InitLanguageDisplay()
  {
    ToggleLocaleDisplay(isEnglishSelected);
  }
  
  public void ToggleLanguage()
  {
    string targetLanguage = LocalizationSettings.SelectedLocale.ToString() == "English (en)" ? "fr" : "en";
    LocalizationSettings.SelectedLocale = LocalizationSettings.AvailableLocales.GetLocale(targetLanguage);
    ToggleLocaleDisplay(isEnglishSelected);
  }
  
  void ToggleLocaleDisplay(bool isEnglish)
  {
    Debug.Log("Toggle language display feedback : " + isEnglish);
    languageDisplays[0].sprite = isEnglish ? activatedLanguageSprites[0] : deactivatedLanguageSprites[0];
    languageDisplays[1].sprite = isEnglish ? deactivatedLanguageSprites[1] : activatedLanguageSprites[1];
  }

  public void Quit() { Application.Quit(); }
}
