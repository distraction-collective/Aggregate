Its important for cadaver prefabs to be low poly, and only hold one material
that has GPU Instancing enabled and that is inert. In order to better optimize flow, as we will
be instantiating about hundreds of them at runtime!