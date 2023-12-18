using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace DesirePaths.UI
{
    public class UIManager : MonoBehaviour
    {
        [SerializeField] private SubtitlesDisplayer _subtitles;
        [SerializeField] private CanvasGroup _fadeElement;

        #region SUBS 
        public void DisplaySubs(string subText)
        {
            _subtitles.Set(subText);
        }
        #endregion

        #region TRANSITION UI EFFECTS

        public void HideNShow()
        {
            StartCoroutine(HideAndShowFade(2f, 0.5f));
        }

        private IEnumerator HideAndShowFade(float duration, float hold)
        {
            float _currentDuration = 0f;
            float _halfDuration = duration / 2f;
            while(_currentDuration < _halfDuration)
            {
                _currentDuration += Time.deltaTime;
                _fadeElement.alpha = Mathf.Lerp(0f, 1f, _currentDuration / _halfDuration);
                yield return null;
            }
            _fadeElement.alpha = 1f;
            _currentDuration = 0f;
            yield return new WaitForSeconds(hold);
            while (_currentDuration < _halfDuration)
            {
                _currentDuration += Time.deltaTime;
                _fadeElement.alpha = Mathf.Lerp(1f, 0f, _currentDuration / _halfDuration);
                yield return null;
            }
            _fadeElement.alpha = 0f;
            yield return null;
        }
        #endregion
    }
}

