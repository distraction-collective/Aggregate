using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

namespace DesirePaths.Landmarks
{
    [RequireComponent(typeof(BoxCollider))]
    public class Landmark : MonoBehaviour
    {
        private BoxCollider _collider => GetComponent<BoxCollider>();
        public UnityEvent OnLandmarkTriggered;
        private string _playerTag = "";
        public string SetPlayerTag
        {
            set
            {
                _playerTag = value;
            }
        }

        private void Awake()
        {
            _collider.isTrigger = true;
        }

        #region COLLISIONS
        private void OnTriggerEnter(Collision collision)
        {
            if(collision.collider.gameObject.tag == _playerTag)
            {
                _collider.enabled = false;
                OnEnter();
            }            
        }

        private void OnTriggerExit(Collision collision)
        {
            if (collision.collider.gameObject.tag == _playerTag)
            {
                OnExit();
            }
        }
        #endregion

        public virtual void OnEnter()
        {
            Debug.Log("landmark entered - " + gameObject.name);
            OnTrigger();
        }

        public virtual void OnExit()
        {
            Debug.Log("landmark exited - " + gameObject.name);
        }

        public virtual void OnTrigger()
        {
            Debug.Log("landmark triggered - " + gameObject.name);
            OnLandmarkTriggered.Invoke();
        }
    }
}
