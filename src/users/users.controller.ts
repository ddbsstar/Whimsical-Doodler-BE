import { Controller, Post, Body } from '@nestjs/common';
import { UsersService } from './users.service';
import { RegisterUserDto } from './dto/register.dto';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post('register')
  registerUser(@Body() registerUserDto: RegisterUserDto): Promise<any> {
    return this.usersService.registerUser(registerUserDto);
  }
}
