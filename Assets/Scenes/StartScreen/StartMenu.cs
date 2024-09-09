using UnityEngine;
using UnityEngine.SceneManagement;

public class StartMenu : MonoBehaviour {
  public void OnButtonStart() { SceneManager.LoadScene("Main"); }
  public void OnButtonQuit() { Application.Quit(); }
}
