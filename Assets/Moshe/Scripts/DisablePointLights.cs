using UnityEngine;

public class DisablePointLights : MonoBehaviour
{
    public float disableDistance = 20f; // Distance at which lights will be disabled
    private Camera mainCamera;

    void Start()
    {
        mainCamera = Camera.main; // Get the main camera
    }

    void Update()
    {
        // Check all point lights in the scene
        foreach (Light light in FindObjectsOfType<Light>())
        {
            if (light.type == LightType.Point)
            {
                // Calculate distance to the camera
                float distance = Vector3.Distance(light.transform.position, mainCamera.transform.position);
                
                // Disable the light if it exceeds the specified distance
                light.enabled = distance <= disableDistance;
            }
        }
    }
}