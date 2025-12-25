_PHI = 0.5 * (sqrt(5) + 1);
_EPSILON = 0.000001;

function float_sign(a) = a < -_EPSILON ? -1 : a > _EPSILON ? 1 : 0;

function float_equals(a, b) = float_sign(a - b) == 0;

function list_sum(list) = list != [] ? [for (i = list) 1] * list : 0;

function list_avg(list) = list_sum(list) / len(list);

function list_slice(list, start=0, end=undef) = let (
    end = end != undef ? end : len(list) - 1
) [for (i = [start:end]) list[i]];

function list_as_kv(list) = [for (i = [0:len(list) - 1])
    object(key = i, value = list[i])
];

function list_keys(list) = [for (i = list) i.key];

function list_values(list) = [for (i = list) i.value];

function list_rotate(list, offset) = [for (i = [0:len(list) - 1])
    list[(i + offset) % len(list)]
];

function _list_sort(kv_list) = len(kv_list) >= 2 ? let (
    pivot = kv_list[floor(0.5 * len(kv_list))].key,
    lesser  = [for (kv = kv_list) if (kv.key  < pivot) kv],
    equal   = [for (kv = kv_list) if (kv.key == pivot) kv],
    greater = [for (kv = kv_list) if (kv.key  > pivot) kv]
) concat(_list_sort(lesser), equal, _list_sort(greater)) : kv_list;

function list_sort(list, sort_value_list=undef) = let(
    sort_keys = sort_value_list != undef ? sort_value_list : list,
    kv_list = [for (i = [0:len(list) - 1])
        object(key = sort_keys[i], value = list[i])
    ],
    sorted_kv_list = _list_sort(kv_list)
) list_values(sorted_kv_list);

function list_take_n(list, n) = [
    if (n > 1)
        for (
            i = [0:len(list) - 1],
            j = list_take_n(list_slice(list, i + 1), n - 1)
        ) concat(list[i], j)
    else if (n == 1)
        for (i = list) [i]
];

function tetrahedron() = object(
    name = "Tetrahedron",
    edges_per_face = 3,
    vertex_radius = sqrt(0.375),
    edge_radius = sqrt(0.125),
    face_radius = sqrt(1 / 24),
    vertices = sqrt(0.125) * [
        for (y = [-1, 1], x = [-1, 1]) [x, y, x * y]
    ]
);

function hexahedron() = object(
    name = "Hexahedron",
    edges_per_face = 4,
    vertex_radius = sqrt(0.75),
    edge_radius = sqrt(0.5),
    face_radius = 0.5,
    vertices = 0.5 * [
        for (z = [-1, 1], y = [-1, 1], x = [-1, 1]) [x, y, z]
    ]
);

function octahedron() = object(
    name = "Octahedron",
    edges_per_face = 3,
    vertex_radius = sqrt(0.5),
    edge_radius = 0.5,
    face_radius = sqrt(1 / 6),
    vertices = sqrt(0.5) * [
        for (offset = [0:2], one = [-1, 1])
            list_rotate([0, 0, one], offset)
    ]
);

function dodecahedron() = object(
    name = "Dodecahedron",
    edges_per_face = 5,
    vertex_radius = _PHI * sqrt(0.75),
    edge_radius = 0.5 * _PHI ^ 2,
    face_radius = sqrt(0.35 + 0.55 * _PHI),
    vertices = 0.5 * _PHI * [
        for (z = [-1, 1], y = [-1, 1], x = [-1, 1]) [x, y, z],
        for (
            offset = [0:2],
            one = _PHI * [-1, 1],
            two = (_PHI - 1) * [-1, 1]
        ) list_rotate([0, one, two], offset)
    ]
);

function icosahedron() = object(
    name = "Icosahedron",
    edges_per_face = 3,
    vertex_radius = sqrt(0.5 + 0.25 * _PHI),
    edge_radius = 0.5 * _PHI,
    face_radius = sqrt(1 / 6 + 0.25 * _PHI),
    vertices = 0.5 * [
        for (offset = [0:2], one = [-1, 1], two = _PHI * [-1, 1])
            list_rotate([0, one, two], offset)
    ]
);

function vertex_angle(a, b, normal) = atan2(
    cross(a, b) * normal, a * b
);

function _edges(vertices, edge_radius) = let (
    kv_vertices = list_as_kv(vertices)
) [
    for (selected_kv_vertices = list_take_n(kv_vertices, 2)) let (
        selected_vertices = list_values(selected_kv_vertices),
        centroid = list_avg(selected_vertices),
        radius = norm(centroid)
    ) if (float_equals(radius, edge_radius))
        list_keys(selected_kv_vertices)
];

function _faces(vertices, face_radius, edges_per_face) = [
    for (
        selected_kv_vertices = list_take_n(
            list_as_kv(vertices), edges_per_face
        )
    ) let (
        selected_vertices = list_values(selected_kv_vertices),
        centroid = list_avg(selected_vertices),
        radius = norm(centroid)
    ) if (float_equals(radius, face_radius)) let (
        normal = -centroid / norm(centroid),
        first_kv_vertex = selected_kv_vertices[0],
        sort_value_list = [
            0,
            for (kv_vertex = list_slice(selected_kv_vertices, 1))
                vertex_angle(
                    first_kv_vertex.value - centroid,
                    kv_vertex.value - centroid,
                    normal
                )
        ],
        sorted_kv_vertices = list_sort(selected_kv_vertices, sort_value_list)
    ) list_keys(sorted_kv_vertices)
];

function _data(obj) = let(
    edges = _edges(obj.vertices, obj.edge_radius),
    faces = _faces(obj.vertices, obj.face_radius, obj.edges_per_face),
    edge_vertices = [for (edge = edges) list_avg(
        [for (edge_vertex = edge) obj.vertices[edge_vertex]]
    )],
    face_vertices = [for (face = faces) list_avg(
        [for (face_vertex = face) obj.vertices[face_vertex]]
    )]
) object(
    name = obj.name,
    edges_per_face = obj.edges_per_face,
    vertex_radius = obj.vertex_radius,
    edge_radius = obj.edge_radius,
    face_radius = obj.face_radius,
    vertices = obj.vertices,
    edges = edges,
    faces = faces,
    edge_vertices = edge_vertices,
    face_vertices = face_vertices
);

module rotate_around(vertex, normal=[0, 0, 1]) {
    rotate(360 * $t, normal)
        rotate(180, list_avg([normal, vertex / norm(vertex)]))
            children();
}

module center_text(text, size) {
    linear_extrude(0.1 * size, center=true) text(
        text,
        size=size,
        halign="center",
        valign="center",
        font="Noto Sans Mono"
    );
}

module debug(obj) {
    face_area = 0.25 * obj.edges_per_face / tan(180 / obj.edges_per_face);
    surface_area = face_area * len(obj.faces);
    echo(object(
        name = obj.name,
        edges_per_face = obj.edges_per_face,
        vertex_diameter = 2 * obj.vertex_radius,
        edge_diameter = 2 * obj.edge_radius,
        face_diameter = 2 * obj.face_radius,
        number_of_vertices = len(obj.vertices),
        number_of_edges = len(obj.edges),
        number_of_faces = len(obj.faces),
        face_area = face_area,
        surface_area = surface_area,
        volume = 1 / 3 * obj.face_radius * surface_area
    ));
}

module debug_vertex(id, vertex, diameter, size=0.1) {
    if ($preview) {
        color("black") translate(vertex)
            rotate(180, list_avg([[0, 0, 1], vertex / norm(vertex)]))
                center_text(str(" ", id, "."), size=size);
    }
}

function d(n) = _data(
    n ==  4 ? tetrahedron() :
    n ==  6 ? hexahedron() :
    n ==  8 ? octahedron() :
    n == 12 ? dodecahedron() :
    n == 20 ? icosahedron() :
    undef
);

//list = [4, 6, 8, 12, 20];
list = [20];
//list = [];
for (kv_n = list_as_kv(list)) {
    obj = d(kv_n.value);
    debug(obj);

    category = object(
        vertices = obj.vertices,
        edges = obj.edge_vertices,
        faces = obj.face_vertices
    );
    top = category.vertices[0];
    highlights = category.faces;

    translate([0, 0, 3 * kv_n.key]) {
        rotate_around(top) {
            polyhedron(points=obj.vertices, faces=obj.faces);
            for (kv_vertex = list_as_kv(highlights)) {
                debug_vertex(kv_vertex.key, kv_vertex.value);
            }
        }
    }
}
