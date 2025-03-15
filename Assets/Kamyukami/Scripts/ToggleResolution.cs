using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class ToggleRenderScale : MonoBehaviour
{
    // Indique si le mode "demi résolution" est activé.
    private bool isHalfResolution = false;
    
    // Référence vers l'asset URP utilisé.
    private UniversalRenderPipelineAsset urpAsset;
    
    // Variables pour l'affichage temporaire du texte.
    private string displayText = "";
    private float displayTime = 0f;

    void Start()
    {
        // Récupère l'asset URP via GraphicsSettings.
        urpAsset = (UniversalRenderPipelineAsset)GraphicsSettings.renderPipelineAsset;
        
        // Cache le curseur de la souris.
        Cursor.visible = false;
    }

    void Update()
    {
        // Utilise le nouveau système d'Input pour détecter la touche O.
        if (Keyboard.current != null && Keyboard.current.tKey.wasPressedThisFrame)
        {
            if (isHalfResolution)
            {
                // Retour au render scale natif.
                urpAsset.renderScale = 1f;
                isHalfResolution = false;
                displayText = "Render Scale: Native";
            }
            else
            {
                // Passe au render scale à 0.5 pour alléger le rendu.
                urpAsset.renderScale = 0.5f;
                isHalfResolution = true;
                displayText = "Render Scale: 0.5x";
            }
            // Affiche le message pendant 3 secondes.
            displayTime = 3f;
        }

        // Réduit le temps d'affichage.
        if (displayTime > 0)
            displayTime -= Time.deltaTime;
    }

    void OnGUI()
    {
        // Affiche le message si le timer est actif.
        if (displayTime > 0)
            GUI.Label(new Rect(10, 10, 200, 20), displayText);
    }
}
