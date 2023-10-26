using UnityEngine;

/// <summary>
/// ce script va probablement ne plus être utile une fois qu'on a notre terrain importé, je le mets dans _unused pour le moment
/// - alpha
/// </summary>
[RequireComponent(typeof(SkinnedMeshRenderer))]
public class MountainGenerator : MonoBehaviour
{
    public int seed = 0; // Global seed value

    [SerializeField]
    private int width = 100;
    [SerializeField]
    private int height = 100;
    [SerializeField]
    private float noiseScale1 = 0.1f;
    [SerializeField]
    private float noiseScale2 = 0.2f;
    [SerializeField]
    private float noiseStrength1 = 1f;
    [SerializeField]
    private float noiseStrength2 = 1f;
    [SerializeField]
    private float peakHeight = 10f;
    [SerializeField]
    private AnimationCurve fadeCurve;
    [SerializeField]
    private int chunkSize = 50;

    private float[,] noiseMap1;
    private float[,] noiseMap2;

    private void Start()
    {
        GenerateNoiseMap();
        GenerateMountain();
    }

    private void OnValidate()
    {
        GenerateNoiseMap();
        GenerateMountain();
    }

    private void GenerateNoiseMap()
    {
        noiseMap1 = new float[width, height];
        noiseMap2 = new float[width, height];

        Random.InitState(seed); // Set the random seed

        for (int z = 0; z < height; z++)
        {
            for (int x = 0; x < width; x++)
            {
                noiseMap1[x, z] = Mathf.PerlinNoise((x + seed) / 100f * noiseScale1, (z + seed) / 100f * noiseScale1) * noiseStrength1;
                noiseMap2[x, z] = Mathf.PerlinNoise((x + seed) / 100f * noiseScale2, (z + seed) / 100f * noiseScale2) * noiseStrength2;
            }
        }
    }

    private void GenerateMountain()
    {
        int numChunksX = Mathf.CeilToInt((float)width / chunkSize);
        int numChunksZ = Mathf.CeilToInt((float)height / chunkSize);

        SkinnedMeshRenderer skinnedMeshRenderer = GetComponent<SkinnedMeshRenderer>();

        Mesh mesh = new Mesh();
        skinnedMeshRenderer.sharedMesh = mesh;

        int totalVertices = width * height;
        int totalTriangles = (width - 1) * (height - 1) * 6;

        Vector3[] vertices = new Vector3[totalVertices];
        int[] triangles = new int[totalTriangles];

        int vertexIndex = 0;
        int triangleIndex = 0;

        float maxDistance = Mathf.Max(width, height) / 2f;

        float xOffset = width / 2f - 0.5f;
        float zOffset = height / 2f - 0.5f;

        float xStep = width / (float)(width - 1);
        float zStep = height / (float)(height - 1);

        for (int chunkZ = 0; chunkZ < numChunksZ; chunkZ++)
        {
            for (int chunkX = 0; chunkX < numChunksX; chunkX++)
            {
                int startX = chunkX * chunkSize;
                int startZ = chunkZ * chunkSize;

                int chunkWidth = Mathf.Min(chunkSize, width - startX);
                int chunkHeight = Mathf.Min(chunkSize, height - startZ);

                for (int z = 0; z < chunkHeight; z++)
                {
                    for (int x = 0; x < chunkWidth; x++)
                    {
                        int mapX = startX + x;
                        int mapZ = startZ + z;

                        float noise1 = noiseMap1[mapX, mapZ];
                        float noise2 = noiseMap2[mapX, mapZ];

                        float y = (noise1 + noise2) * peakHeight;

                        // Calculate the distance from the center
                        float distance = Vector2.Distance(new Vector2(mapX - xOffset, mapZ - zOffset), Vector2.zero);

                        // Normalize the distance
                        float normalizedDistance = distance / maxDistance;

                        // Invert the normalized distance
                        float invertedDistance = 1f - normalizedDistance;

                        // Apply the inverted distance to the curve
                        float fade = fadeCurve.Evaluate(invertedDistance);
                        y *= fade;

                        vertices[vertexIndex] = new Vector3(x * xStep - xOffset, y, z * zStep - zOffset);

                        if (x < chunkWidth - 1 && z < chunkHeight - 1)
                        {
                            int a = vertexIndex;
                            int b = vertexIndex + width;
                            int c = vertexIndex + width + 1;
                            int d = vertexIndex + 1;

                            triangles[triangleIndex++] = a;
                            triangles[triangleIndex++] = b;
                            triangles[triangleIndex++] = c;

                            triangles[triangleIndex++] = a;
                            triangles[triangleIndex++] = c;
                            triangles[triangleIndex++] = d;
                        }

                        vertexIndex++;
                    }
                }
            }
        }

        mesh.vertices = vertices;
        mesh.triangles = triangles;
        mesh.RecalculateNormals();
    }
}
