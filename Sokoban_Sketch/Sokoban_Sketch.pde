
// ids

final int id_floor  = 0;
final int id_player = 1;
final int id_box    = 2;
final int id_wall   = 3;

// directions

final int dir_empty = -1;
final int dir_up    = 0;
final int dir_down  = 1;
final int dir_left  = 2;
final int dir_right = 3;

// game state

int queued_dir = dir_empty;
int player_x = 0;
int player_y = 0;
int box_x = 4;
int box_y = 4;

// game initial parameters

int board_offset = 40;

int wg = 11;
int hg = 11;
int grid_cell_size = 20;
int grid_cell_spacing = 30;
int grid[][] = new int[hg][wg];

class PosInc {
  int x;
  int y;
  PosInc(int x, int y) {
    this.x = x;
    this.y = y;
  }
}

void setup() {
  size(600, 600);
  background(100);
  noFill();

  grid[player_x][player_y] = id_player;
  grid[box_x][box_y] = id_box;
}

void keyPressed() {
  if (key == CODED) {
    switch(keyCode) {
    case UP:
      queued_dir = dir_up;
      break;
    case DOWN:
      queued_dir = dir_down;
      break;
    case LEFT:
      queued_dir = dir_left;
      break;
    case RIGHT:
      queued_dir = dir_right;
      break;
    default:
      queued_dir = dir_empty;
    }
  }
}

boolean in_boundaries(int x, int y) {
  if (y < 0 || y >= hg || x < 0 || x >= wg) return false;
  return true;
}

PosInc apply_direction_in_bounds(int x, int y, int direction) {
  int mov_x = 0;
  int mov_y = 0;
  switch(direction) {

  case dir_up:
    if ((y - 1) < 0) return null;   
    mov_y -= 1;

    break;

  case dir_down:
    if ((y + 1) >= hg) return null;
    mov_y += 1;
    break;

  case dir_left:
    if ((x - 1) < 0) return null;
    mov_x -= 1;
    break;

  case dir_right:
    if ((x + 1) >= hg) return null;
    mov_x += 1;
    break;
  }

  if ((mov_x != 0 || mov_y != 0) && grid[y + mov_y][x + mov_x] == id_wall) return null;

  return new PosInc(mov_x, mov_y);
}

void consume_queued_dir_player() {
  if (queued_dir == dir_empty) return;
  int new_x = player_x;
  int new_y = player_y;
  
  
  PosInc inc = apply_direction_in_bounds(player_x, player_y, queued_dir);  
  if (inc != null) {
    println("Player_Can_Move");
    new_x = player_x + inc.x; 
    new_y = player_y + inc.y;
    if (grid[new_y][new_x] == id_box) {
      println("Box_In_Next_Step");
      PosInc box_inc = apply_direction_in_bounds(new_x, new_y, queued_dir);
      if (inc != null) {
        player_x = new_x;
        player_y = new_y;
        grid[new_y + box_inc.y][new_x + box_inc.x] = id_box;
      }
    } else {
      println("Moving_Player");
      player_x = new_x;
      player_y = new_y;
    }
  }

  // todo goncalo: move everything out of the grid into lists

  // todo goncalo: improve this. Dont' need to reset everything in the grid.
  
  for (int ih = 0; ih < hg; ih++) {
    for (int iw = 0; iw < wg; iw++) {
      grid[ih][iw] = id_floor;
    }
  }

  grid[player_y][player_x] = id_player;
  grid[box_y][box_x] = id_box;

  grid[8][8] = id_wall;

  queued_dir = dir_empty;
}

void draw() {
  // interaction

  consume_queued_dir_player();

  // rendering
  for (int ih = 0; ih < hg; ih++) {
    for (int iw = 0; iw < wg; iw++) {
      int screen_x = (iw * grid_cell_spacing) + board_offset;
      int screen_y = (ih * grid_cell_spacing) + board_offset;

      int id = grid[ih][iw];
      switch(id) {
      case id_floor:
        fill(10 + iw * 2, 10 + ih, 0);
        break;
      case id_player:
        fill(150, 50, 50);
        break;
      case id_box:
        fill(150, 150, 50);
        break;
      case id_wall:
        fill(50, 150, 150);
        break;
      default:
        throw new RuntimeException("Unknown id in the grid");
      }

      rect(screen_x, screen_y, grid_cell_size, grid_cell_size);
    }
  }
}
