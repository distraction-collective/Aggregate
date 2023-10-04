using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// Rotates skybox parameter according to a float. Does it in LateUpdate to be in sync with other animation update cycles.
/// -Gucci
/// </summary>

public class RotateSkyboxProgressively : MonoBehaviour
{
    
    [SerializeField] private float skyboxRotationSpeed;

    // Update is called once per frame
    void LateUpdate()
    {
        RenderSettings.skybox.SetFloat("_Rotation", Time.time * skyboxRotationSpeed);
    }
}
