using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;

[RequireComponent(typeof(CanvasGroup))]
public class SubtitlesSwitcher : MonoBehaviour
{
    CanvasGroup _canvas => GetComponent<CanvasGroup>();
    public static UnityEvent<bool> Show = new UnityEvent<bool>();

    private void OnEnable()
    {
        Show.AddListener(Toggle);
    }

    private void OnDisable()
    {
        Show.RemoveListener(Toggle);
    }

    void Toggle(bool toggle) {
        _canvas.alpha = toggle ? 1f : 0f;
    }
}
