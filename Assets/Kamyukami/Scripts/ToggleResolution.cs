using UnityEngine;

public class ToggleResolution : MonoBehaviour
{
    // Indique si la résolution est actuellement restreinte.
    private bool isRestricted = false;
    
    // Stocke la résolution complète (initiale).
    private int fullWidth;
    private int fullHeight;

    // Variables pour l'affichage du texte.
    private string displayText = "";
    private float displayTime = 0f;

    void Start()
    {
        // Récupère la résolution actuelle (par exemple, la résolution native de l'écran).
        fullWidth = Screen.currentResolution.width;
        fullHeight = Screen.currentResolution.height;
    }

    void Update()
    {
        // Vérifie si la touche "O" est pressée.
        if (Input.GetKeyDown(KeyCode.O))
        {
            if (isRestricted)
            {
                // Retour à la résolution complète.
                Screen.SetResolution(fullWidth, fullHeight, Screen.fullScreen);
                isRestricted = false;
                displayText = "Resolution set to Native";
            }
            else
            {
                // Passage en mode restreint à 1920x1080.
                Screen.SetResolution(1920, 1080, Screen.fullScreen);
                isRestricted = true;
                displayText = "Resolution set to 1920x1080";
            }
            // Afficher le texte pendant 3 secondes.
            displayTime = 3f;
        }

        // Réduire le temps d'affichage.
        if (displayTime > 0)
        {
            displayTime -= Time.deltaTime;
            if (displayTime < 0)
                displayTime = 0;
        }
    }

    void OnGUI()
    {
        // Affiche le texte si le timer est actif.
        if (displayTime > 0)
        {
            GUI.Label(new Rect(10, 10, 200, 20), displayText);
        }
    }
}
