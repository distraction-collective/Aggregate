using DesirePaths;
using TMPro;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.UI;
using UnityEngine.Localization.Settings;

public class PauseMenu : MonoBehaviour {
  public GameObject pauseCanvas;
  //public InputAction inputAction;
  public Button defaultButton;
  //private bool playing = true;
  
  [Header("Button animations")]
  [SerializeField] private Sprite[] deactivatedLanguageSprites = new Sprite[2];
  [SerializeField] private Sprite[] activatedLanguageSprites = new Sprite[2];
  [SerializeField] private Image[] languageDisplays = new Image[2];
  
  [Header("Text animations")]
  [SerializeField] private Color focusTextColor = Color.white;
  [SerializeField] private Color unfocusedTextColor = Color.grey;
  [SerializeField] private TMP_Text resumeButtonText;
  [SerializeField] private TMP_Text language1Text;
  [SerializeField] private TMP_Text language2Text;

  public static UnityEvent OnResumeButtonPressed = new UnityEvent();

  private bool isEnglishSelected
  {
    get
    {
      return LocalizationSettings.SelectedLocale.ToString() == "English (en)";
    }
  }

  void OnEnable() {
    GameManager.OnGameStateChanged.AddListener(GameStateChanged);
    defaultButton.onClick.AddListener(delegate
    {
      OnResumeButtonPressed.Invoke();
      Resume();
    });
    InitLanguageDisplay();
  }

  void OnDisable()
  {
    defaultButton.onClick.RemoveAllListeners();
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
    //Debug.Log("Toggle language display feedback : " + isEnglish);
    languageDisplays[0].sprite = isEnglish ? activatedLanguageSprites[0] : deactivatedLanguageSprites[0];
    languageDisplays[1].sprite = isEnglish ? deactivatedLanguageSprites[1] : activatedLanguageSprites[1];
    language1Text.color = isEnglish ? focusTextColor : unfocusedTextColor;
    language2Text.color = isEnglish ? unfocusedTextColor : focusTextColor;
  }

  public void Quit() { Application.Quit(); }
}
