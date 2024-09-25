using UnityEngine;
using UnityEngine.Events;

public class TriggerEvent : MonoBehaviour
{
    // UnityEvent param�trable depuis l'inspector
    [SerializeField]
    private UnityEvent onTriggerEnterEvent;

    // Le tag que le trigger doit d�tecter
    [SerializeField]
    private string triggerTag = "Player_Collider";

    // D�tecte l'entr�e dans le trigger
    private void OnTriggerEnter(Collider other)
    {
        // V�rifie si l'objet entrant a le tag correct
        if (other.CompareTag(triggerTag))
        {
            // D�clenche l'UnityEvent
            onTriggerEnterEvent.Invoke();
        }
    }
}