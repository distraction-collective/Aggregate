using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class MenuDepthOfField : MonoBehaviour
{
    public Volume globalVolume; // Reference to the Global Volume component
    public GameObject targetObject; // The target object that activates/deactivates the effects

    [Header("Depth of Field Settings")]
    public float activeFocalLength = 10f; // Focal length when activated
    public float inactiveFocalLength = 0f; // Focal length when deactivated

    [Header("Bloom Settings")]
    public float activeBloomIntensity = 5f; // Bloom intensity when activated
    public float inactiveBloomIntensity = 0f; // Bloom intensity when deactivated
    public float activeBloomThreshold = 1f; // Bloom threshold when activated
    public float inactiveBloomThreshold = 0f; // Bloom threshold when deactivated

    private DepthOfField depthOfFieldEffect; // Reference to the Depth of Field effect
    private Bloom bloomEffect; // Reference to the Bloom effect

    private void Start()
    {
        // Ensure the Global Volume is assigned
        if (globalVolume == null)
        {
            Debug.LogError("Global Volume is not assigned! Please assign it in the inspector.");
            return;
        }

        // Try to get the Depth of Field effect from the Global Volume's profile
        if (globalVolume.profile.TryGet<DepthOfField>(out depthOfFieldEffect))
        {
            Debug.Log("Depth of Field effect found.");
        }
        else
        {
            Debug.LogError("Depth of Field effect not found in the Global Volume profile! Please add a Depth of Field effect.");
        }

        // Try to get the Bloom effect from the Global Volume's profile
        if (globalVolume.profile.TryGet<Bloom>(out bloomEffect))
        {
            Debug.Log("Bloom effect found.");
        }
        else
        {
            Debug.LogError("Bloom effect not found in the Global Volume profile! Please add a Bloom effect.");
        }
    }

    private void Update()
    {
        // Check if the target object is active or not and adjust effects accordingly
        if (targetObject.activeSelf)
        {
            SetFocalLength(activeFocalLength); // Set the focal length when active
            SetBloomIntensity(activeBloomIntensity); // Set bloom intensity when active
            SetBloomThreshold(activeBloomThreshold); // Set bloom threshold when active
        }
        else
        {
            SetFocalLength(inactiveFocalLength); // Set the focal length when inactive
            SetBloomIntensity(inactiveBloomIntensity); // Set bloom intensity when inactive
            SetBloomThreshold(inactiveBloomThreshold); // Set bloom threshold when inactive
        }
    }

    private void SetFocalLength(float focalLength)
    {
        // Check if the depth of field effect is available and set the focal length
        if (depthOfFieldEffect != null)
        {
            depthOfFieldEffect.active = focalLength > 0; // Enable or disable the effect based on focal length
            depthOfFieldEffect.focalLength.value = focalLength; // Set the focal length directly
            Debug.Log($"Depth of Field focal length set to: {focalLength}"); // Log the amount for debugging
        }
        else
        {
            Debug.LogError("Depth of Field effect is not available!");
        }
    }

    private void SetBloomIntensity(float intensity)
    {
        // Check if the bloom effect is available and set the intensity
        if (bloomEffect != null)
        {
            bloomEffect.active = intensity > 0; // Enable or disable the effect based on intensity
            bloomEffect.intensity.value = intensity; // Set the bloom intensity directly
            Debug.Log($"Bloom intensity set to: {intensity}"); // Log the amount for debugging
        }
        else
        {
            Debug.LogError("Bloom effect is not available!");
        }
    }

    private void SetBloomThreshold(float threshold)
    {
        // Check if the bloom effect is available and set the threshold
        if (bloomEffect != null)
        {
            bloomEffect.threshold.value = threshold; // Set the bloom threshold directly
            Debug.Log($"Bloom threshold set to: {threshold}"); // Log the amount for debugging
        }
        else
        {
            Debug.LogError("Bloom effect is not available!");
        }
    }
}
