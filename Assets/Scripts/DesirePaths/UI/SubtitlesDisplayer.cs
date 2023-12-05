using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using TMPro;
using System.Text;

namespace DesirePaths.UI
{
    public class SubtitlesDisplayer : MonoBehaviour
    {
        [SerializeField] private TMP_Text _subtitlesDisplay;
        [SerializeField] private float _displayDuration = 3f;
        [SerializeField] private int maxChars = 105;

        private void Awake()
        {
            Clear();
        }

        public void Set(string text)
        {
            StartCoroutine(ShowSubs(text));
        }

        private IEnumerator ShowSubs(string text)
        {
            List<string> lines = SplitSubs(text);
            for(int i = 0; i < lines.Count; i ++)
            {
                if(lines[i].Length != 0 && !string.IsNullOrEmpty(lines[i])) {
                    _subtitlesDisplay.text = lines[i];
                    yield return new WaitForSeconds(_displayDuration);
                }                
            }            
            Clear();
        }

        // splits text into several lines if the text is too long to fit on screen
        List<string> SplitSubs(string s)
        {
            if (s.Length < maxChars)
            {
                List<string> result = new List<string>(); // a bit verbose but eh
                result.Add(s);
                return result;
            }
            string separator = "--";
            StringBuilder sb = new StringBuilder();
            for (int i = 0; i < s.Length; i++)
            {
                if (i % maxChars == 0)
                    sb.Append(separator);
                sb.Append(s[i]);
            }
            Debug.Log("Formatted subs : " + sb.ToString());
            string formatted = sb.ToString();
            return new List<string>(formatted.Split(separator));
        }

        public void Clear()
        {
            _subtitlesDisplay.text = "";
        }
    }
}

