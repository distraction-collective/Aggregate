
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
  [SerializeField] private Button languageButton;
  [SerializeField] private Sprite[] deactivatedLanguageSprites = new Sprite[2];
  [SerializeField] private Sprite[] activatedLanguageSprites = new Sprite[2];
  [SerializeField] private Image[] languageDisplays = new Image[2];

  void OnEnable() {
    GameManager.OnGameStateChanged.AddListener(GameStateChanged);
    languageButton.onClick.AddListener(Language);
    InitLanguageDisplay();
  }

  void OnDisable()
  {
    languageButton.onClick.RemoveAllListeners();
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

  private void InitLanguageDisplay()
  {
    SetLanguage(LocalizationSettings.SelectedLocale.ToString());
  }
  
  private void Language()
  {
    Debug.Log("Currently selected locale : " + LocalizationSettings.SelectedLocale.ToString());
    string targetLanguage = LocalizationSettings.SelectedLocale.ToString() == "en" ? "fr" : "en";
    SetLanguage(targetLanguage);
  }

  public void Pause() {
    pauseCanvas.SetActive(true);
    defaultButton.Select();
    InitLanguageDisplay();
  }
  public void Resume() {
    pauseCanvas.SetActive(false);
  }

  void SetLanguage(string locale)
  {
    Debug.Log("SET LANGUAGE : " + locale);
    LocalizationSettings.SelectedLocale =
      LocalizationSettings.AvailableLocales.GetLocale(locale);
    ToggleLocaleDisplay(locale == "en");
  }

  void ToggleLocaleDisplay(bool isEnglish)
  {
    languageDisplays[0].sprite = isEnglish == true ? activatedLanguageSprites[0] : deactivatedLanguageSprites[0];
    languageDisplays[1].sprite = isEnglish == true ? deactivatedLanguageSprites[1] : activatedLanguageSprites[1];
  }

  public void Quit() { Application.Quit(); }
}
