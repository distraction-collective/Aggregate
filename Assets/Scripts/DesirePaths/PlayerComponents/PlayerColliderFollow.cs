using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace DesirePaths.PlayerComponents
{
    public class PlayerColliderFollow : MonoBehaviour
    {
        [SerializeField] private Transform _target;

        private void FixedUpdate()
        {
            this.transform.position = _target.transform.position;
        }
    }
}

