using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

namespace DesirePaths.Narration {
  public class NarrationManager : MonoBehaviour {
    [SerializeField]
    TextAsset _script;
    private int _currentLine = 0;
    private List<string> _scriptLines;
    public enum ScriptResponseCode {
      NO_SCRIPT, // no script found
      COMPLETE,  // all the lines of the script have been displayed
      UPDATED    // a new line of script has been retrieved
    }

    public UnityAction UpdateNarrationAction;
    public NarrationUpdateEvent NarrationUpdated = new NarrationUpdateEvent();

    private void Awake() { UpdateNarrationAction += OnNarrationUpdated; }

    private void OnDisable() { UpdateNarrationAction -= OnNarrationUpdated; }

    void OnNarrationUpdated() {
      ScriptResponseCode response = GetNextLine(out string line);
      if (response == ScriptResponseCode.UPDATED) {
        if (NarrationUpdated != null)
          NarrationUpdated.Invoke(line);
      }
    }

    public ScriptResponseCode GetNextLine(out string line) {
      line = "";
      if (_script == null)
        return ScriptResponseCode.NO_SCRIPT;
      if (_scriptLines == null || _scriptLines.Count == 0)
        LoadScript();
      if (_currentLine == _scriptLines.Count)
        return ScriptResponseCode.COMPLETE;
      line = _scriptLines[_currentLine];
      _currentLine += 1;
      return ScriptResponseCode.UPDATED;
    }

    void LoadScript() {
      _scriptLines = new List<string>(_script.text.Split('\n'));
    }
  }
}
