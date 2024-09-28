using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;
using Cinemachine;

namespace DesirePaths.Tools
{
    [RequireComponent(typeof(CinemachineBrain))]
    public class CameraSwitcher : MonoBehaviour
    {
        public static UnityEvent<bool> ToggleCameraMovement = new UnityEvent<bool>();
        CinemachineBrain cineBrain => GetComponentInParent<CinemachineBrain>();

        private void OnEnable()
        {
            ToggleCameraMovement.AddListener(ToggleCam);
        }

        private void OnDisable()
        {
            ToggleCameraMovement.RemoveListener(ToggleCam);
        }

        void ToggleCam(bool toggle)
        {
            cineBrain.enabled = toggle;
        }
    }
}

