using UnityEngine;

public class WaterFootstepManager : MonoBehaviour
{
    [SerializeField] private AudioClip[] waterFootstepAudioClips;  // Water footstep sounds
    [SerializeField] private AudioSource footstepAudioSource;      // Reference to the AudioSource for water footsteps
    private bool isInWater = false;              // Track if the player is in water

    private void Start()
    {
        // Ensure the AudioSource is assigned
        if (footstepAudioSource == null)
        {
            footstepAudioSource = GetComponent<AudioSource>();

            if (footstepAudioSource == null)
            {
                Debug.LogError("AudioSource is missing. Please attach an AudioSource component to the player object.");
            }
        }
    }

    private void OnTriggerEnter(Collider other)
    {
        if (other.CompareTag("WaterArea"))
        {
            isInWater = true;  // When entering the water area
        }
    }

    private void OnTriggerExit(Collider other)
    {
        if (other.CompareTag("WaterArea"))
        {
            isInWater = false;  // When leaving the water area
        }
    }

    // This function should be called via Animation Event when a footstep occurs
    public void OnFootstep(AnimationEvent animationEvent)
    {
        // Only handle water footsteps, and let ThirdPersonController handle normal footsteps
        if (isInWater && animationEvent.animatorClipInfo.weight > 0.5f)
        {
            if (waterFootstepAudioClips.Length > 0)
            {
                var index = Random.Range(0, waterFootstepAudioClips.Length);  // Pick a random water footstep sound
                footstepAudioSource.PlayOneShot(waterFootstepAudioClips[index]);  // Play the selected sound
            }
        }
    }
}
