using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace DesirePaths.UI
{
    public class UIManager : MonoBehaviour
    {
        [SerializeField] private SubtitlesDisplayer _subtitles;

        #region SUBS 
        public void DisplaySubs(string subText)
        {
            _subtitles.Set(subText);
        }
        #endregion
    }
}

