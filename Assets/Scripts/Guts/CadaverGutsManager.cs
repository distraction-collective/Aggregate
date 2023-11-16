using System.Collections;
using System.Collections.Generic;
using MonsterLove.Collections;
using UnityEngine;
using UnityEngine.Splines;
using Unity.Mathematics;

public class CadaverGutsManager : MonoBehaviour
{
    [Header("Player Info")]
    public Transform _gutsOrigin;
    public Transform playerTransform;
    [Header("Cadavers and splines")]
    public List<GameObject> currentCadaverArray = new List<GameObject>();
    public SplineContainer _splineContainer;
    public SplineExtrude _splineGeometry;
    [Header("Data")]
    [SerializeField] private PoolManager cadaverPool;
    [SerializeField] private CadaverData _data;

    //Raycasts
    RaycastHit _hit;
    
    // Start is called before the first frame update
    void Start()
    {
        InitializePool();
        InitializeOriginKnot();
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    //Getters
    public int GetNumberOfCadavers()
    {
        return currentCadaverArray.Count;
    }


    /// <summary>
    /// Deposits cadaver at playerTransform Position, using a raycast above player and pointing downwards,
    /// we get the exact position and normal offset where we should put the body
    /// </summary>

    public void DepositCadaverOnPosition()
    {
        GameObject newCadaver;
        int randPrefabIndex = UnityEngine.Random.Range(0, _data.randomCadaverPrefabs.Length); //Lets choose a random prefab
        if (Physics.Raycast(playerTransform.position + Vector3.up * _data.basicDetectionHeightDifferential, -Vector3.up, out _hit, Mathf.Infinity, _data.layerToPutCadaver)){
            var randPrefab = _data.randomCadaverPrefabs[randPrefabIndex];
            newCadaver = cadaverPool.spawnObject(randPrefab, _hit.point, Quaternion.identity);
            currentCadaverArray.Add(newCadaver);
            newCadaver.transform.rotation = Quaternion.FromToRotation(transform.up, _hit.normal) * newCadaver.transform.rotation;
        }
        else //We failed to hit, proceed to just put it where playerTransform is - itll be ugly but it still works
        {
            var randPrefab = _data.randomCadaverPrefabs[randPrefabIndex];
            newCadaver = cadaverPool.spawnObject(randPrefab, playerTransform.position + Vector3.up * _data.cadaverDepositExtraHeight, Quaternion.identity);
            currentCadaverArray.Add(newCadaver);
        }
        ConnectSplineToNewCadaver(newCadaver.transform, _hit.point, _hit.normal);
    }

    
    public void ConnectSplineToNewCadaver(Transform newCadaverTransform, Vector3 hitpoint, Vector3 hitnormal)
    {
        //Make sure previous knot goes in direction of final knot and set tangent mode to Auto Smooth
        var lastCurveIndex = _splineContainer.Spline.Count - 1;
        var lastCurve = _splineContainer.Spline.GetCurve(lastCurveIndex);
        Vector3 DistanceBetweenTwoCadavers;
        Vector3 lastCadaverPosition;
        float numberofCadavers = GetNumberOfCadavers();
        if (numberofCadavers > 1)
        {
            lastCadaverPosition = currentCadaverArray[currentCadaverArray.Count - 2].transform.position;
        }
        else lastCadaverPosition = _gutsOrigin.position;
        DistanceBetweenTwoCadavers = hitpoint - lastCadaverPosition;
        lastCurve.Tangent1 = Vector3ToFloat3(DistanceBetweenTwoCadavers.normalized);
        _splineContainer.Spline.SetTangentModeNoNotify(lastCurveIndex, TangentMode.AutoSmooth);
        //Add intermediate knots with random number between 1-2, then place them with raycast with sin function to add variation
        int randomNumberOfKnots = UnityEngine.Random.Range(1, _data.maxNumberOfKnotsBetweenCadavers);
        Vector3 randomIterativePosition;
        Vector3 positionToPut;
        for (int i=0; i < randomNumberOfKnots; i++)
        {
            //Placement along distance
            randomIterativePosition = lastCadaverPosition + (DistanceBetweenTwoCadavers * ((float)(i+1) / (float)(randomNumberOfKnots+1)) - DistanceBetweenTwoCadavers.normalized/((float)randomNumberOfKnots +2));
        
            Physics.Raycast(randomIterativePosition + Vector3.up * _data.basicDetectionHeightDifferential, -Vector3.up, out _hit, Mathf.Infinity, _data.layerToPutCadaver);
#if UNITY_EDITOR
            Debug.DrawRay(randomIterativePosition + Vector3.up * _data.basicDetectionHeightDifferential, -Vector3.up * 10f, Color.magenta);
            //Debug.Log("random number of knots: " + randomNumberOfKnots + " i+1 = " + (i + 1) + " current distance between knots: " + ((float)(i + 1) / (float)(randomNumberOfKnots+1)));
            
#endif
            positionToPut = _hit.point + Vector3.up * _data.cadaverDepositExtraHeight;
            positionToPut += Vector3.Cross(DistanceBetweenTwoCadavers, Vector3.up).normalized * _data.intermediateKnotSinAmplitude * Mathf.Sin(Time.time); //Add sin amplitude to left side
            _splineContainer.Spline.Add(new BezierKnot(_splineContainer.transform.InverseTransformPoint(positionToPut))); //Inverse transform point because splines are rendered in local space                  
            lastCurveIndex += 1;
            _splineContainer.Spline.SetTangentModeNoNotify(lastCurveIndex, TangentMode.AutoSmooth);//Autosmooth it
        }
        //Add ending knot and make sure that in Tangent corresponds to the normal 
        Unity.Mathematics.float3 endTangent = Vector3ToFloat3(hitnormal * _data.autoBezierCurveAmplitude);

        _splineContainer.Spline.Add(new BezierKnot(_splineContainer.transform.InverseTransformPoint(newCadaverTransform.position + Vector3.up * _data.cadaverDepositExtraHeight), endTangent, endTangent));
        _splineContainer.Spline.SetTangentModeNoNotify(_splineContainer.Spline.Count - 1, TangentMode.AutoSmooth);
        _splineGeometry.Rebuild(); //Rebuild geometry to accomodate new spline knot 
    }

    /// <summary>
    /// Knots take tangent arguments as float3, faster compiling
    /// </summary>
    /// <param name="v"></param>
    /// <returns></returns>
    public static Unity.Mathematics.float3 Vector3ToFloat3(Vector3 v)
    {
        Unity.Mathematics.float3 tan = new float3();
        tan.x = v.x;
        tan.y = v.y;
        tan.z = v.y;
        return tan;
    }

    public static Vector3 Float3ToVector3(float3 f)
    {
        Vector3 v = new Vector3();
        v.x = f.x;
        v.y = f.y;
        v.y = f.z;
        return v;
    }

    public void InitializeOriginKnot()
    {
        _splineContainer.Spline.Add(new BezierKnot(_splineContainer.transform.InverseTransformPoint(_gutsOrigin.position + Vector3.up * _data.cadaverDepositExtraHeight)));
        _splineContainer.Spline.SetTangentMode(TangentMode.AutoSmooth);
        _splineGeometry.Rebuild(); //Rebuild geometry to accomodate new spline knot 
    }

    void InitializePool()
    {
        foreach (var cadaverPrefab in _data.randomCadaverPrefabs)
        {
            cadaverPool.warmPool(cadaverPrefab, _data.maxPopPerPrefab);
        }
    }
}
