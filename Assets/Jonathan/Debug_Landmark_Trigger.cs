using UnityEngine;
using UnityEngine.Events;

public class TriggerEvent : MonoBehaviour
{
    // UnityEvent paramétrable depuis l'inspector
    [SerializeField]
    private UnityEvent onTriggerEnterEvent;

    // Le tag que le trigger doit détecter
    [SerializeField]
    private string triggerTag = "Player_Collider";

    // Détecte l'entrée dans le trigger
    private void OnTriggerEnter(Collider other)
    {
        // Vérifie si l'objet entrant a le tag correct
        if (other.CompareTag(triggerTag))
        {
            // Déclenche l'UnityEvent
            onTriggerEnterEvent.Invoke();
        }
    }
}