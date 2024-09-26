using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.Rendering;
using UnityEngine.Rendering.PostProcessing;

namespace DesirePaths.Tools {

    [RequireComponent(typeof(Volume))]
    public class PostProcessSwitcher : MonoBehaviour
    {
        /// <summary>
        /// Active ou désactive un post-process volume
        /// </summary>
        public static UnityEvent<PostProcessType, bool> SwitchPP = new UnityEvent<PostProcessType, bool>();
        private State _currentState;
        private float _blendVal = 0f;

        [SerializeField] private PostProcessType postProcessType = PostProcessType.UNSET;
        /* A UNCOMMENT SI VOUS VOULEZ ANIMER LE BLEND
            DESACTIVE POUR LE MOMENT PARCE QUE LE MODE MET LE TIMESCALE A ZERO
        private float _blendSpeed = 0.1f;
        */

        private Volume _volume
        {
            get
            {
                return GetComponent<Volume>();
            }
        }
        
        public enum PostProcessType
        {
            UNSET,
            MENU
        }
        
        private enum State
        {
            idle,
            fadingIn,
            fadingOut
        }

        private void OnEnable()
        {
            /* A UNCOMMENT SI VOUS VOULEZ ANIMER LE BLEND
            DESACTIVE POUR LE MOMENT PARCE QUE LE MODE MET LE TIMESCALE A ZERO
            _blendVal = _volume.weight;
            */
            SwitchPP.AddListener(Activate);
        }

        private void OnDisable()
        {
            SwitchPP.RemoveListener(Activate);
        }

        private void Activate(PostProcessType pp, bool activate)
        {
            Debug.Log("SWITCH POST PROCESS : " + pp.ToString());
            if (_volume == null || pp != postProcessType) return;
            _currentState = activate ? State.fadingIn : State.fadingOut;
            // Comment la ligne en dessous si vous voulez animer le blend progressivement
            SetBlend(activate ? 1f : 0f);
        }

        /* A UNCOMMENT SI VOUS VOULEZ ANIMER LE BLEND
        DESACTIVE POUR LE MOMENT PARCE QUE LE MODE MET LE TIMESCALE A ZERO

        void Update()
        {
            if (_currentState == State.idle) return;
            if (_currentState == State.fadingIn)
            {
                _blendVal += Time.deltaTime * _blendSpeed;
                SetBlend(_blendVal);
            } else if (_currentState == State.fadingOut)
            {
                _blendVal -= Time.deltaTime * _blendSpeed;
                SetBlend(_blendVal);
            }
        } */


        void SetBlend(float f)
        {
            _blendVal = Mathf.Clamp(f, 0f, 1f);
            if (Mathf.Approximately(f, 1f) || Mathf.Approximately(f, 0f) )
            {
                _currentState = State.idle;
            } 
            _volume.weight = _blendVal;
            Debug.Log("Set volume weight : " + _blendVal);
        }
    }
}
