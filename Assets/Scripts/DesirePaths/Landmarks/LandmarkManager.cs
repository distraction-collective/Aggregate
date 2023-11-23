using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Linq;

namespace DesirePaths.Landmarks
{
    public class LandmarkManager : MonoBehaviour
    {
        /// <summary>
        /// Used to keep track if all the pillars have been activated
        /// </summary>
        private int _pillarCount = 0;
        private int _completedPillarsCount = 0;

        [SerializeField] private List<Landmark> _landmarks;
        public enum LandmarkEvents
        {
            PILLAR_ACTIVATED,
            LANDMARK_ENTERED,
            ALL_PILLARS_ACTIVATED,
            ALL_LANDMARKS_ENTERED
        }
        public LandmarkEvent OnLandmarkTriggered;
        public LandmarkEvent OnLandmarkCompletion;

        private bool _pillarsCompleted = false;
        private string _playerTag = "";

        private void Awake()
        {
            _landmarks.ForEach(x =>
            {
                x.SetPlayerTag = _playerTag;
                if (x.GetType() == typeof(Pillar)) _pillarCount += 1;
            });
            SubscribeToLandmarkTriggers(true);
        }

        private void OnDisable()
        {
            SubscribeToLandmarkTriggers(false);
        }

        void SubscribeToLandmarkTriggers(bool subscribe)
        {
            _landmarks.ForEach(x =>
            {
                if(subscribe)
                {
                    x.OnLandmarkTriggered.AddListener(delegate { LandmarkTriggered(x); });
                } else
                {
                    x.OnLandmarkTriggered.RemoveAllListeners();
                }                
            });
        }

        void LandmarkTriggered(Landmark l)
        {
            if(l.GetType() == typeof(Pillar))
            {
                if (_pillarsCompleted) return;
                OnLandmarkTriggered.Invoke(LandmarkEvents.PILLAR_ACTIVATED);
                _completedPillarsCount += 1;
                if (_completedPillarsCount == _pillarCount)
                {
                    _pillarsCompleted = true;
                    OnLandmarkCompletion.Invoke(LandmarkEvents.ALL_PILLARS_ACTIVATED);
                }
            } else {
                OnLandmarkTriggered.Invoke(LandmarkEvents.LANDMARK_ENTERED);
            }
        }
    }
}
